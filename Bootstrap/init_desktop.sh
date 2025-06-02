#!/bin/bash

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and install required packages
apt update && apt install -y \
    sudo \
    wget \
    curl \
    gnupg \
    unzip \
    software-properties-common \
    dbus-x11 \
    x11-xserver-utils \
    xterm \
    git \
    mate-desktop-environment \
    mate-desktop-environment-extras \
    mate-terminal \
    mate-panel \
    mate-session-manager \
    xserver-xorg \
    xinit \
    tigervnc-standalone-server

# Create users
useradd -m -s /bin/bash eoin
echo "eoin:eoin" | chpasswd
usermod -aG sudo eoin

useradd -m -s /bin/bash matthew
echo "matthew:matthew" | chpasswd
usermod -aG sudo matthew

# Setup KasmVNC
mkdir -p /opt/kasmvnc
cd /opt/kasmvnc
wget https://github.com/novnc/noVNC/archive/refs/heads/master.zip
unzip master.zip
mv noVNC-master novnc
rm master.zip

# Create index.html to redirect to vnc.html for user convenience
cat > /opt/kasmvnc/novnc/index.html << 'EOF'
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; url=vnc.html" />
    <title>Redirecting...</title>
  </head>
  <body>
    <p>Redirecting to <a href="vnc.html">vnc.html</a>...</p>
  </body>
</html>
EOF

# Download and install websockify
cd /opt/kasmvnc
wget https://github.com/novnc/websockify/archive/refs/heads/master.zip -O websockify.zip
unzip websockify.zip
mv websockify-master websockify
rm websockify.zip
chmod +x /opt/kasmvnc/websockify/run

# Create start-vnc script
cat > /usr/local/bin/start-vnc.sh << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <username> <display_number> <port>"
    exit 1
fi

USERNAME=$1
DISPLAY_NUM=$2
PORT=$3

# Kill any existing VNC session
vncserver -kill :$DISPLAY_NUM 2>/dev/null || true

# Start new VNC session
su - $USERNAME -c "vncserver :$DISPLAY_NUM -geometry 1280x800 -depth 24 -localhost no"

# Start websockify
/opt/kasmvnc/websockify/run $PORT localhost:$((5900 + $DISPLAY_NUM)) --web=/opt/kasmvnc/novnc &
EOF

chmod +x /usr/local/bin/start-vnc.sh

# Set VNC password for eoin
echo 'eoin' | su - eoin -c "mkdir -p ~/.vnc && vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"

# Set VNC password for matthew
echo 'matthew' | su - matthew -c "mkdir -p ~/.vnc && vncpasswd -f > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"

# Start the desktops for both users
/usr/local/bin/start-vnc.sh eoin 1 6901 &
/usr/local/bin/start-vnc.sh matthew 2 6902 &

# Print access information
E_PORT_6901=${RUNPOD_TCP_PORT_6901:-6901}
E_PORT_6902=${RUNPOD_TCP_PORT_6902:-6902}
IP=$(curl -s ifconfig.me)
echo "Access eoin's desktop at: http://$IP:$E_PORT_6901"
echo "Access matthew's desktop at: http://$IP:$E_PORT_6902"

# Git setup (configure user and remote, but do not auto-commit or push)
cd /workspace
if [ ! -d .git ]; then
  git init
fi
git config user.name "ForgeRoboticsAI"
git config user.email "forgeroboticsai@gmail.com"
git remote remove origin 2>/dev/null || true
git remote add origin git@github.com:ForgeRoboticsAI/Seam-detection-.git 2>/dev/null || true 