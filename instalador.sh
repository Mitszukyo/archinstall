#!/bin/bash
set -e

echo "[+] Iniciando instalação automatizada..."

# ============================================================
# BOOTLOADER GRUB + Tema CyberRe (instalação segura)
# ============================================================
echo "[+] Instalando GRUB e configurando tema CyberRe..."

sudo pacman -S --noconfirm grub efibootmgr os-prober unzip

sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Baixar e aplicar o tema CyberRe (sem autenticação)
sudo mkdir -p /boot/grub/themes
curl -L https://github.com/ChrisTitusTech/GRUB-Themes/archive/refs/heads/master.zip -o /tmp/grub-themes.zip
unzip -o /tmp/grub-themes.zip -d /tmp
sudo cp -r /tmp/GRUB-Themes-master/CyberRe /boot/grub/themes/

# Aplicar tema CyberRe
sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/CyberRe/theme.txt"|' /etc/default/grub
sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/CyberRe/theme.txt"|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Alterar ordem padrão do kernel (priorizar Linux normal)
sudo sed -i 's|GRUB_DEFAULT=.*|GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux"|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# ============================================================
# JetBrains Toolbox
# ============================================================
echo "[+] Instalando JetBrains Toolbox..."
curl -fsSL https://download.jetbrains.com/toolbox/jetbrains-toolbox.tar.gz -o /tmp/jetbrains-toolbox.tar.gz
sudo tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /opt
sudo ln -sf /opt/jetbrains-toolbox*/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox
/opt/jetbrains-toolbox*/jetbrains-toolbox & disown

# ============================================================
# SNAPSHOTS AUTOMÁTICOS (Snapper)
# ============================================================
echo "[+] Configurando Snapper..."
sudo pacman -S --noconfirm snapper
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USER\"/" /etc/snapper/configs/root
sudo sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USER\"/" /etc/snapper/configs/home
sudo systemctl enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer

# ============================================================
# NETWORK E INTERFACE DE LOGIN
# ============================================================
echo "[+] Habilitando NetworkManager e GDM..."
sudo pacman -S --noconfirm gdm networkmanager
sudo systemctl enable NetworkManager
sudo systemctl enable gdm

# ============================================================
# DOCKER
# ============================================================
echo "[+] Instalando e habilitando Docker..."
sudo pacman -S --noconfirm docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# ============================================================
# HYPERLAND + DOTFILES END4
# ============================================================
echo "[+] Instalando Hyprland e configurando..."
sudo pacman -S --noconfirm hyprland waybar swaybg wl-clipboard xdg-desktop-portal thunar

mkdir -p /home/$USER/.config/hyprland
curl -L https://github.com/end-4/dots-hyprland/archive/refs/heads/main.zip -o /tmp/hyprland.zip
unzip -o /tmp/hyprland.zip -d /tmp
cp -r /tmp/dots-hyprland-main/* /home/$USER/.config/hyprland
chown -R $USER:$USER /home/$USER/.config/hyprland

# ============================================================
# ATALHOS DO HYPERLAND
# ============================================================
echo "[+] Aplicando atalhos do Hyprland..."
cat > /home/$USER/.config/hyprland/hyprland.conf <<EOT
# Mod = Win (Super)
bind = Mod+Enter, exec, kitty
bind = Mod+Q, close
bind = Mod+F, toggle_floating
bind = Mod+H, focus_left
bind = Mod+L, focus_right
bind = Mod+K, focus_up
bind = Mod+J, focus_down
bind = Mod+Shift+H, move_left
bind = Mod+Shift+L, move_right
bind = Mod+Shift+K, move_up
bind = Mod+Shift+J, move_down
bind = Mod+Space, toggle_layout
bind = Mod+1, workspace 1
bind = Mod+2, workspace 2
bind = Mod+3, workspace 3
bind = Mod+4, workspace 4
bind = Mod+5, workspace 5
bind = Mod+6, workspace 6
bind = Mod+7, workspace 7
bind = Mod+8, workspace 8
bind = Mod+9, workspace 9
bind = Mod+0, workspace 10
bind = Mod+Shift+1, move_to_workspace 1
bind = Mod+Shift+2, move_to_workspace 2
bind = Mod+Shift+3, move_to_workspace 3
bind = Mod+Shift+4, move_to_workspace 4
bind = Mod+Shift+5, move_to_workspace 5
bind = Mod+Shift+6, move_to_workspace 6
bind = Mod+Shift+7, move_to_workspace 7
bind = Mod+Shift+8, move_to_workspace 8
bind = Mod+Shift+9, move_to_workspace 9
bind = Mod+Shift+0, move_to_workspace 10
bind = Mod+Tab, next_window
bind = Mod+R, reload
bind = Mod+Ctrl+Q, restart
bind = Mod+*, exec, /home/$USER/.config/hyprland/theme_selector.sh
EOT
chown -R $USER:$USER /home/$USER/.config/hyprland

# ============================================================
# TERMINAL KITTY
# ============================================================
echo "[+] Instalando Kitty..."
sudo pacman -S --noconfirm kitty
mkdir -p /home/$USER/.config/kitty
cat > /home/$USER/.config/kitty/kitty.conf <<EOT
background_opacity 0.85
include /usr/share/kitty/themes/Catppuccin.conf
shell zsh
EOT
chown -R $USER:$USER /home/$USER/.config/kitty

# ============================================================
# NEOVIM + PACOTES DE DESENVOLVIMENTO
# ============================================================
echo "[+] Instalando Neovim e dependências..."
sudo pacman -S --noconfirm neovim jdk-openjdk maven gradle python python-pip nodejs npm gcc make gdb sqlite postgresql
sudo -u $USER git clone --depth 1 https://github.com/LazyVim/starter.git /home/$USER/.config/nvim
sudo -u $USER nvim --headless +Lazy! +qall

# ============================================================
# MULTIMÍDIA E UTILITÁRIOS
# ============================================================
echo "[+] Instalando apps multimídia..."
sudo pacman -S --noconfirm firefox spotify-launcher discord pulseaudio pavucontrol alsa-utils feh

echo "[✅] Instalação concluída com sucesso!"
echo "→ Reinicie o computador para aplicar todas as alterações."