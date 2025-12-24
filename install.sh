#!/bin/sh

# Inspired from crowdsec.net installation scripts

# #MIT License

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

unknown_os() {
    echo "Unfortunately, your operating system distribution and version are not supported by this script."
    echo
    echo "You can override the OS detection by setting os= and dist= prior to running this script."
    echo
    echo "The following operating systems are currently supported:"
    echo "Ubuntu 22+, Debian 11+, Raspbian 11+, CentOS 8+, RHEL 8+, AlmaLinux 8+,"
    echo "Rocky 8+, Oracle Linux 8+, Fedora, and Red Hat Enterprise Server 8+"
    echo
    echo "For example, to force Ubuntu Trusty: os=ubuntu dist=trusty ./script.sh"
    echo
    echo "Please file an issue at https://github.com/ytcalifax/dotfiles"
    exit 1
}

detect_os() {
    if [ -z "$os" ] && [ -z "$dist" ]; then
        if [ -e /etc/os-release ]; then
            . /etc/os-release
            os=$ID
            dist=$(echo "$VERSION_ID" | awk -F '.' '{ print $1 }')

        elif command -v lsb_release >/dev/null; then
            # get major version (e.g. '5' or '6')
            dist=$(lsb_release -r | cut -f2 | awk -F '.' '{ print $1 }')

            # get os (e.g. 'centos', 'redhatenterpriseserver', etc)
            os=$(lsb_release -i | cut -f2 | awk '{ print tolower($1) }')

        elif [ -e /etc/oracle-release ]; then
            dist=$(cut -f5 --delimiter=' ' /etc/oracle-release | awk -F '.' '{ print $1 }')
            os='ol'

        elif [ -e /etc/fedora-release ]; then
            dist=$(cut -f3 --delimiter=' ' /etc/fedora-release)
            os='fedora'

        elif [ -e /etc/redhat-release ]; then
            os_hint=$(awk '{ print tolower($1) }' /etc/redhat-release)
            if [ "$os_hint" = "centos" ]; then
                dist=$(awk '{ print $3 }' /etc/redhat-release | awk -F '.' '{ print $1 }')
                os='centos'
            else
                dist=$(awk '{ print tolower($7) }' /etc/redhat-release | cut -f1 --delimiter='.')
                os='redhatenterpriseserver'
            fi

        else
            unknown_os
        fi
    fi

    # remove whitespace from OS and dist name and transform to lowercase
    os=$(echo "$os" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    dist=$(echo "$dist" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

    if [ -z "$dist" ]; then
        echo "Detected operating system as $os."
    else
        echo "Detected operating system as $os/$dist."
    fi

    # version validation
    case $os in
        ubuntu)
            if [ "$dist" -lt 22 ] 2>/dev/null; then
                unknown_os
            fi
            ;;
        debian)
            if [ "$dist" -lt 11 ] 2>/dev/null; then
                unknown_os
            fi
            ;;
        raspbian)
            if [ "$dist" -lt 11 ] 2>/dev/null; then
                unknown_os
            fi
            ;;
        centos | rhel | almalinux | rocky | ol | redhatenterpriseserver)
            if [ "$dist" -lt 8 ] 2>/dev/null; then
                unknown_os
            fi
            ;;
    esac

    if [ "$os" = "ol" ] || [ "$os" = "el" ] && [ "$dist" -gt 7 ]; then
        _skip_pygpgme=1
    else
        _skip_pygpgme=0
    fi
}

curl_check_deb() {
    echo "Checking for 'curl' binary..."
    if command -v curl >/dev/null; then
        echo "Detected 'curl' binary..."
    else
        echo "Installing 'curl' binary..."
        if ! apt-get install -q -y curl; then
            echo "This script was unable to install 'curl' binary. Please,"
            echo "check your default OS's package repositories because curl should work."
            echo
            echo "Please file an issue at https://github.com/ytcalifax/dotfiles"
            echo "if you think the behavior is not intended."
            exit 1
        fi
    fi
}

curl_check_rhel() {
    echo "Checking for 'curl' binary..."
    if command -v curl >/dev/null; then
        echo "Detected 'curl' binary..."
    else
        echo "Installing 'curl' binary..."
        yum install -d0 -e0 -y curl
    fi
}

install_repo_rhel() {
    if [ "$os" != "fedora" ]; then
        if [ "$dist" -ge 8 ] 2>/dev/null; then
            echo "Checking for 'crb' repository..."
            if yum repolist --enabled 2>/dev/null | grep -qE 'crb|powertools|codeready'; then
                echo "Detected 'crb' repository..."
            else
                echo "Enabling 'crb' repository..."
                dnf config-manager --set-enabled crb 2>/dev/null || \
                dnf config-manager --set-enabled powertools 2>/dev/null || \
                yum-config-manager --enable crb 2>/dev/null || \
                yum-config-manager --enable powertools 2>/dev/null || true
            fi
        fi
    fi

    echo "Checking for 'epel-release' repository..."
    if rpm -q epel-release >/dev/null 2>&1; then
        echo "Detected 'epel-release' repository..."
    else
        echo "Installing 'epel-release' repository..."
        yum install -d0 -e0 -y dnf-plugins-core epel-release
    fi
}

install_sysctl_config() {
    echo "Downloading 'sysctl' performance tuning configuration..."
    SYSCTL_CONFIG_URL="https://raw.githubusercontent.com/ytcalifax/dotfiles/refs/heads/master/etc/sysctl.d/99-performance-tuning.conf"
    TEMP_SYSCTL=$(mktemp)

    if ! curl -sS "$SYSCTL_CONFIG_URL" -o "$TEMP_SYSCTL"; then
        echo "Failed to download 'sysctl' configuration"
        rm -f "$TEMP_SYSCTL"
        return 1
    fi

    echo "Installing 'sysctl' performance tuning configuration..."
    mkdir -p /etc/sysctl.d
    cp "$TEMP_SYSCTL" /etc/sysctl.d/99-performance-tuning.conf

    echo "Applying 'sysctl' parameters..."
    sysctl -p /etc/sysctl.d/99-performance-tuning.conf >/dev/null 2>&1

    rm -f "$TEMP_SYSCTL"
    echo "Sysctl configuration installed and applied successfully"
}

install_bashrc_customizations() {
    echo "Downloading 'bashrc' customizations..."
    BASHRC_URL="https://raw.githubusercontent.com/ytcalifax/dotfiles/refs/heads/master/etc/bashrc"
    TEMP_BASHRC=$(mktemp)

    if ! curl -sS "$BASHRC_URL" -o "$TEMP_BASHRC"; then
        echo "Failed to download 'bashrc' customizations"
        rm -f "$TEMP_BASHRC"
        return 1
    fi

    echo "Installing 'bashrc' customizations..."
    # Check if customizations already exist
    if grep -q "# system-wide customizations" /etc/bashrc 2>/dev/null; then
        echo "Bashrc customizations already present, skipping..."
        rm -f "$TEMP_BASHRC"
        return 0
    fi

    # Insert customizations before the vim modeline comment
    if grep -q "# vim:ts=4:sw=4" /etc/bashrc; then
        # Remove the vim modeline, append our content, then add modeline back
        sed -i '/# vim:ts=4:sw=4/d' /etc/bashrc
        cat "$TEMP_BASHRC" >> /etc/bashrc
        echo "" >> /etc/bashrc
        echo "# vim:ts=4:sw=4" >> /etc/bashrc
    else
        # No vim modeline, just append
        cat "$TEMP_BASHRC" >> /etc/bashrc
    fi

    rm -f "$TEMP_BASHRC"
    echo "Bashrc customizations installed successfully"
}

install_starship_config() {
    echo "Downloading 'starship.rs' configuration..."
    STARSHIP_CONFIG_URL="https://raw.githubusercontent.com/ytcalifax/dotfiles/refs/heads/master/.config/starship.toml"
    TEMP_CONFIG=$(mktemp)

    if ! curl -sS "$STARSHIP_CONFIG_URL" -o "$TEMP_CONFIG"; then
        echo "Failed to download 'starship.rs' configuration"
        rm -f "$TEMP_CONFIG"
        return 1
    fi

    # install for root
    echo "Installing 'starship.rs' configuration for root..."
    mkdir -p /root/.config
    cp "$TEMP_CONFIG" /root/.config/starship.toml

    # install for sudoer
    if [ -n "$SUDO_USER" ]; then
        echo "Installing 'starship.rs' configuration for $SUDO_USER..."
        SUDO_HOME=$(eval echo ~"$SUDO_USER")
        mkdir -p "$SUDO_HOME/.config"
        cp "$TEMP_CONFIG" "$SUDO_HOME/.config/starship.toml"
        chown "$SUDO_USER:$SUDO_USER" "$SUDO_HOME/.config/starship.toml"
    fi

    rm -f "$TEMP_CONFIG"
    echo "Configuration for 'starship.rs' installed successfully"
}

main() {
    detect_os
    case $os in
        ubuntu | debian | raspbian)
            curl_check_deb
            apt-get remove -qq -y ufw 2>/dev/null || true
            apt-get install -qq -y tar nano tuned firewalld fastfetch btop
            curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir /usr/bin -y
            chmod +x /usr/bin/starship

            # clean up
            apt-get -y autoremove
            apt-get autoclean
            apt-get clean

            # enable and start services
            systemctl enable firewalld --now
            systemctl enable tuned --now

            # set all-around appropriate profile
            tuned-adm profile latency-performance

            # add sshd firewall rule
            firewall-cmd --permanent --zone=public --add-service=ssh
            firewall-cmd --reload

            # install starship config
            install_starship_config

            # install sysctl config
            install_sysctl_config

            # install bashrc customizations
            install_bashrc_customizations
            ;;
        centos | rhel | fedora | redhatenterpriseserver | almalinux | rocky | ol)
            curl_check_rhel
            install_repo_rhel
            dnf copr enable atim/starship epel-"${dist}"-"$(uname -m)" -y 2>/dev/null || true
            yum remove -y ufw 2>/dev/null || true
            yum install -d0 -e0 -y tar nano tuned firewalld fastfetch btop starship

            # clean up
            yum -y autoremove
            yum clean all

            # enable and start services
            systemctl enable firewalld --now
            systemctl enable tuned --now

            # set all-around appropriate profile
            tuned-adm profile latency-performance

            # add sshd firewall rule
            firewall-cmd --permanent --zone=public --add-service=ssh
            firewall-cmd --reload

            # install starship config
            install_starship_config

            # install sysctl config
            install_sysctl_config

            # install bashrc customizations
            install_bashrc_customizations
            ;;
        *)
            echo "This system is not supported (yet) by this script."
            echo "Please refer to the README.md for installation instructions,"
            echo "or file an issue at https://github.com/ytcalifax/dotfiles if you"
            echo "believe the behavior is not intended."
            exit 1
            ;;
    esac

    echo
}

if [ "$(id -u)" -ne 0 ] || [ -z "${SUDO_USER:-}" ]; then
    echo "This script must be run as a regular user via sudo."
    echo
    echo "Please file an issue at https://github.com/ytcalifax/dotfiles"
    echo "if you think the behavior is not intended."
    exit 1
fi

main

