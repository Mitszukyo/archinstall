#!/bin/bash
# Script enxuto: BSPWM + Hyprland + apps básicos + usuário + login
# Execute no chroot ou após montar ROOT/HOME

# Pedir nomes e senhas
read -p "Digite o nome do usuário: " USER
read -s -p "Digite a senha do usuário: " PASS
echo
read -s -p "Digite a senha do ROOT: " ROOTPASS
echo

# Atualizar pacman
pacman -Syu --noconfirm

# Instalar base mínima
pacman -S --noconfirm xorg xorg-xinit bspwm sxhkd polybar \
    hyprland waybar swaybg wl-clipboard xdg-desktop-portal \
    networkmanager firefox vim neovim git sudo gdm

# Configurar root
echo "root:$ROOTPASS" | chpasswd

# Criar usuário
useradd -m -G wheel -s /bin/bash $USER
echo "$USER:$PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Ativar NetworkManager e GDM
systemctl enable NetworkManager
systemctl enable gdm

# Criar diretórios de configuração BSPWM
mkdir -p /home/$USER/.config/bspwm
mkdir -p /home/$USER/.config/sxhkd

# Arquivo de configuração BSPWM básico
cat > /home/$USER/.config/bspwm/bspwmrc <<EOT
#!/bin/sh
bspc monitor -d I II III IV V
bspc config border_width 2
bspc config window_gap 10
bspc config focus_follows_pointer true
bspc config pointer_follows_monitor true
bspc config split_ratio 0.5
bspc config borderless_monocle true
bspc config gapless_monocle true
EOT

# Arquivo de binds básicos
cat > /home/$USER/.config/sxhkd/sxhkdrc <<EOT
# Binds comuns
super + {h,j,k,l}
    bspc node -f {west,south,north,east}
super + Return
    alacritty
super + w
    firefox
EOT

chown -R $USER:$USER /home/$USER/.config

echo "Instalação concluída! Reinicie e selecione seu usuário no GDM."
