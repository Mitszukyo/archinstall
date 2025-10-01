#!/bin/bash
# Script seguro ThinkPad T14 Arch Linux atualizado (2025-10-01) com autocomplete no terminal
# Execute no live Arch conectado à internet

# -----------------------------
# VARIÁVEIS DE USUÁRIO
# -----------------------------
read -p "Digite o nome do usuário: " USER
read -s -p "Digite a senha do usuário: " PASS
echo
read -s -p "Digite a senha do ROOT: " ROOTPASS
echo

# -----------------------------
# ESCOLHA DAS PARTIÇÕES
# -----------------------------
lsblk
echo "=== Atenção: identifique as partições do Linux ROOT, SWAP, HOME e EFI EXISTENTE ==="
read -p "Digite a partição ROOT Linux (ex: /dev/nvme0n1p2): " ROOTPART
read -p "Digite a partição SWAP Linux (ex: /dev/nvme0n1p3): " SWAPPART
read -p "Digite a partição HOME Linux (ex: /dev/nvme0n1p4): " HOMEPART
read -p "Digite a partição EFI EXISTENTE (ex: /dev/nvme0n1p1): " EFIPART

echo "Você escolheu:"
echo "ROOT: $ROOTPART"
echo "SWAP: $SWAPPART"
echo "HOME: $HOMEPART"
echo "EFI : $EFIPART"
read -p "Está correto? (s/n): " CONFIRM
if [[ "$CONFIRM" != "s" ]]; then
    echo "Saindo. Revise as partições e rode o script novamente."
    exit 1
fi

# -----------------------------
# FORMATAÇÃO COM VERIFICAÇÃO
# -----------------------------
echo "[+] Formatando ROOT e SWAP"
read -p "Confirma formatar ROOT ($ROOTPART)? TODOS OS DADOS SERÃO PERDIDOS (s/n): " ROOTCONF
if [[ "$ROOTCONF" == "s" ]]; then
    mkfs.btrfs -f $ROOTPART
else
    echo "Abortado."
    exit 1
fi

read -p "Confirma formatar SWAP ($SWAPPART)? (s/n): " SWAPCONF
if [[ "$SWAPCONF" == "s" ]]; then
    mkswap $SWAPPART
    swapon $SWAPPART
else
    echo "Abortado."
    exit 1
fi

read -p "Confirma formatar HOME ($HOMEPART)? TODOS OS DADOS SERÃO PERDIDOS (s/n): " HOMECONF
if [[ "$HOMECONF" == "s" ]]; then
    mkfs.btrfs -f $HOMEPART
else
    echo "Abortado."
    exit 1
fi

# ⚠️ NÃO FORMATAMOS A PARTIÇÃO EFI (vem do Windows)

# -----------------------------
# MONTAGEM
# -----------------------------
mount $ROOTPART /mnt
mkdir -p /mnt/home
mount $HOMEPART /mnt/home
mkdir -p /mnt/boot/efi
mount $EFIPART /mnt/boot/efi

# -----------------------------
# BASE DO ARCH
# -----------------------------
pacstrap /mnt base base-devel linux linux-lts linux-firmware vim neovim git sudo networkmanager btrfs-progs snapper bash-completion zsh

# -----------------------------
# FSTAB
# -----------------------------
genfstab -U /mnt >> /mnt/etc/fstab

# -----------------------------
# CHROOT
# -----------------------------
arch-chroot /mnt /bin/bash <<EOF

# LOCALE, HOSTNAME
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "ThinkPad" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ThinkPad.localdomain ThinkPad" >> /etc/hosts

# SENHAS
echo "root:$ROOTPASS" | chpasswd

# CRIAR USUÁRIO
useradd -m -G wheel -s /bin/bash $USER
echo "$USER:$PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# BOOTLOADER GRUB Sleek
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
os-prober
grub-mkconfig -o /boot/grub/grub.cfg
git clone https://github.com/jacksaur/sleek-grub.git /boot/grub/themes/sleek
sed -i 's/^GRUB_THEME=.*/GRUB_THEME="\/boot\/grub\/themes\/sleek\/theme.txt"/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# SNAPSHOTS AUTOMÁTICOS
snapper -c root create-config /
snapper -c home create-config /home
sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USER\"/" /etc/snapper/configs/root
sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"$USER\"/" /etc/snapper/configs/home
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

# NETWORK
systemctl enable NetworkManager
systemctl enable gdm

# HYPERLAND + DOTFILES END4
pacman -S --noconfirm hyprland waybar swaybg wl-clipboard xdg-desktop-portal thunar
git clone https://github.com/end-4/dots-hyprland.git /home/$USER/.config/hyprland
chown -R $USER:$USER /home/$USER/.config/hyprland

# ATALHOS HYPRLAND (END4) PREDEFINIDOS
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
chown -R $USER:$USER /home/$USER/.config/hyprland/hyprland.conf

# TERMINAL KITTY COM AUTOCOMPLETE
pacman -S --noconfirm kitty
mkdir -p /home/$USER/.config/kitty
cat > /home/$USER/.config/kitty/kitty.conf <<EOT
background_opacity 0.85
include /usr/share/kitty/themes/Catppuccin.conf
shell zsh
EOT
chown -R $USER:$USER /home/$USER/.config/kitty

# NEOVIM (pronto para Java e COBOL)
pacman -S --noconfirm jdk-openjdk maven gradle python python-pip nodejs npm gcc make gdb sqlite postgresql
sudo -u $USER git clone https://github.com/LazyVim/starter.git /home/$USER/.config/nvim
sudo -u $USER nvim --headless +Lazy! +qall

# MULTIMÍDIA E UTILITÁRIOS
pacman -S --noconfirm firefox spotify discord pulseaudio pavucontrol alsa-utils feh

# GDM (Tela de login)
pacman -S --noconfirm gdm
systemctl enable gdm

EOF

echo "[+] Instalação concluída com segurança! Reinicie o computador."
