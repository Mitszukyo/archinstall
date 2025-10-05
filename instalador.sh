#!/bin/bash
# Script de instalação limpa para Arch Linux (Hyprland + apps + JetBrains + Docker + Snapper)

set -euo pipefail
USER_NAME="$USER"  # Usuário atual

echo "[+] Atualizando pacotes..."
sudo pacman -Syu --noconfirm

# -----------------------------
# BOOTLOADER GRUB + Tema CyberRe
# -----------------------------
echo "[+] Instalando GRUB e dependências..."
sudo pacman -S --noconfirm grub efibootmgr os-prober

echo "[+] Instalando GRUB no EFI..."
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
sudo os-prober
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "[+] Instalando tema CyberRe..."
sudo mkdir -p /boot/grub/themes
git clone https://github.com/ChrisTitusTech/GRUB-Themes.git /tmp/grub-themes
sudo cp -r /tmp/grub-themes/CyberRe /boot/grub/themes/
sudo sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/CyberRe/theme.txt"|' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# === Ajustar GRUB para iniciar com o kernel Linux padrão ===
echo "Configurando GRUB para iniciar com o kernel Linux padrão..."

# Atualiza a lista de entradas do GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Identifica o índice do kernel 'Linux' (não LTS)
index=$(grep -i "Arch Linux, with Linux " /boot/grub/grub.cfg | grep -n "" | grep -v "lts" | head -n 1 | cut -d: -f1)

if [ -n "$index" ]; then
    # Subtrai 1 porque o GRUB começa do 0
    entry_number=$((index - 1))
    sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=${entry_number}/" /etc/default/grub
    echo "GRUB configurado para inicializar com o kernel Linux (entrada $entry_number)."
else
    echo "Não foi possível encontrar a entrada do kernel Linux padrão. Nenhuma alteração feita."
fi

# Regera o GRUB com a nova configuração
sudo grub-mkconfig -o /boot/grub/grub.cfg

# -----------------------------
# JETBRAINS STUDENT PACK
# -----------------------------
echo "[+] Instalando JetBrains Toolbox..."
curl -fsSL https://download.jetbrains.com/toolbox/jetbrains-toolbox.tar.gz -o /tmp/jetbrains-toolbox.tar.gz
sudo tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /opt
sudo ln -sf /opt/jetbrains-toolbox*/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox
/opt/jetbrains-toolbox*/jetbrains-toolbox &

# -----------------------------
# SNAPSHOTS AUTOMÁTICOS (Snapper)
# -----------------------------
echo "[+] Configurando Snapper..."
sudo snapper -c root create-config /
sudo snapper -c home create-config /home
sudo sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USER_NAME\"/" /etc/snapper/configs/root
sudo sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USER_NAME\"/" /etc/snapper/configs/home
sudo systemctl enable snapper-timeline.timer
sudo systemctl enable snapper-cleanup.timer

# -----------------------------
# NETWORK + DISPLAY MANAGER
# -----------------------------
sudo systemctl enable NetworkManager
sudo systemctl enable gdm

# -----------------------------
# DOCKER
# -----------------------------
sudo pacman -S --noconfirm docker
sudo systemctl enable docker
sudo usermod -aG docker "$USER_NAME"

# -----------------------------
# HYPRLAND + DOTFILES END4
# -----------------------------
echo "[+] Instalando Hyprland e utilitários..."
sudo pacman -S --noconfirm hyprland waybar swaybg wl-clipboard xdg-desktop-portal thunar kitty

git clone https://github.com/end-4/dots-hyprland.git /home/$USER_NAME/.config/hyprland
sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/hyprland

# Atalhos Hyprland
cat > /home/$USER_NAME/.config/hyprland/hyprland.conf <<EOT
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
bind = Mod+*, exec, /home/$USER_NAME/.config/hyprland/theme_selector.sh
EOT
sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/hyprland/hyprland.conf

# -----------------------------
# TERMINAL KITTY
# -----------------------------
mkdir -p /home/$USER_NAME/.config/kitty
cat > /home/$USER_NAME/.config/kitty/kitty.conf <<EOT
background_opacity 0.85
include /usr/share/kitty/themes/Catppuccin.conf
shell zsh
EOT
sudo chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config/kitty

# -----------------------------
# NEOVIM + DEV TOOLS
# -----------------------------
sudo pacman -S --noconfirm jdk-openjdk maven gradle python python-pip nodejs npm gcc make gdb sqlite postgresql
sudo -u $USER_NAME git clone https://github.com/LazyVim/starter.git /home/$USER_NAME/.config/nvim
sudo -u $USER_NAME nvim --headless +Lazy! +qall

# -----------------------------
# MULTIMÍDIA E UTILITÁRIOS
# -----------------------------
sudo pacman -S --noconfirm firefox spotify discord pulseaudio pavucontrol alsa-utils feh

echo "[+] Instalação concluída! Reinicie o computador."