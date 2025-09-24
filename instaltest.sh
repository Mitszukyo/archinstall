#!/bin/bash
# ==========================================
# Script Arch Linux para VM 32GB - Diogo
# BSPWM + Hyprland, Neovim e dev tools leves
# Execute no Live Arch conectado à internet
# ==========================================

set -e

# -------------------------------
# 1. Variáveis do usuário
# -------------------------------
read -p "Digite o nome do usuário: " USER
read -s -p "Digite a senha do usuário: " PASS
echo
read -s -p "Digite a senha do ROOT: " ROOTPASS
echo

# -------------------------------
# 2. Partições (ajustadas para VM)
# -------------------------------
# EFI 200MB / ROOT 20GB / SWAP 2GB / HOME 8GB
EFI="/dev/sda1"
ROOT="/dev/sda2"
SWAP="/dev/sda3"
HOME="/dev/sda4"

# -------------------------------
# 3. Formatar e montar
# -------------------------------
mkfs.fat -F32 $EFI
mkfs.btrfs -f $ROOT
mkswap $SWAP
swapon $SWAP

# Criar subvolumes Btrfs
mount $ROOT /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

# Montar subvolumes
mount -o compress=zstd,subvol=@ $ROOT /mnt
mkdir -p /mnt/home
mount -o compress=zstd,subvol=@home $ROOT /mnt/home
mkdir -p /mnt/boot
mount $EFI /mnt/boot

# -------------------------------
# 4. Instalar base Arch
# -------------------------------
pacstrap /mnt base base-devel linux linux-firmware vim neovim git sudo networkmanager

# -------------------------------
# 5. Fstab
# -------------------------------
genfstab -U /mnt >> /mnt/etc/fstab

# -------------------------------
# 6. Chroot e configuração
# -------------------------------
arch-chroot /mnt /bin/bash <<EOF

# Timezone e locale
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Hostname
echo "VM-Arch" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 VM-Arch.localdomain VM-Arch" >> /etc/hosts

# Senhas
echo "root:$ROOTPASS" | chpasswd

# Criar usuário
useradd -m -G wheel -s /bin/bash $USER
echo "$USER:$PASS" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Bootloader
pacman -S --noconfirm grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
os-prober
grub-mkconfig -o /boot/grub/grub.cfg

# Instalar BSPWM + Hyprland (minimal)
pacman -S --noconfirm bspwm sxhkd polybar xorg xorg-xinit
pacman -S --noconfirm hyprland waybar swaybg wl-clipboard xdg-desktop-portal

# Instalar dev tools leves
pacman -S --noconfirm python python-pip gcc make gdb sqlite postgresql nodejs npm openjdk

# Neovim + terminal
mkdir -p /home/$USER/.config/nvim/lua
cat > /home/$USER/.config/nvim/lua/terminal.lua <<EOT
require("toggleterm").setup{
  size = 20,
  open_mapping = [[<c-\\>]],
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  persist_size = true,
  direction = 'horizontal'
}
vim.api.nvim_set_keymap("n", "<Leader>t", ":ToggleTerm<CR>", {noremap = true, silent = true})
EOT

chown -R $USER:$USER /home/$USER/.config/nvim

# Multimídia leve e utilitários
pacman -S --noconfirm firefox pulseaudio pavucontrol alsa-utils

# Ativar NetworkManager
systemctl enable NetworkManager

EOF

echo "Instalação concluída! Reinicie a VM."
