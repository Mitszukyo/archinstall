#!/bin/bash
# Script profissional ThinkPad T14 Arch Linux
# Execute no live Arch conectado à internet

# Variáveis
read -p "Digite o nome do usuário: " USER
read -s -p "Digite a senha do usuário: " PASS
echo
read -s -p "Digite a senha do ROOT: " ROOTPASS
echo
read -p "Digite a partição ROOT Linux (ex: /dev/sda2): " ROOTPART
read -p "Digite a partição SWAP Linux (ex: /dev/sda3): " SWAPPART

# Formatar ROOT e SWAP
mkfs.btrfs -f $ROOTPART
mkswap $SWAPPART
swapon $SWAPPART

# Montar ROOT
mount $ROOTPART /mnt
mkdir -p /mnt/home

# Instalar base Arch
pacstrap /mnt base base-devel linux linux-firmware vim neovim git sudo networkmanager

# Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt /bin/bash <<EOF

# Timezone e locale
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

# Hostname
echo "ThinkPad" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 ThinkPad.localdomain ThinkPad" >> /etc/hosts

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

# Instalar WM e barra
pacman -S --noconfirm bspwm sxhkd polybar xorg xorg-xinit
pacman -S --noconfirm hyprland waybar swaybg wl-clipboard xdg-desktop-portal

# Instalar desenvolvimento
pacman -S --noconfirm jdk-openjdk maven gradle python python-pip nodejs npm gcc make gdb sqlite postgresql
yay -S --noconfirm eclipse-java

# Neovim + toggleterm
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

# Plugins LSP e snippets
cat > /home/$USER/.config/nvim/init.lua <<EOT
require('lazy').setup({
  'neovim/nvim-lspconfig',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
  'L3MON4D3/LuaSnip',
  'rafamadriz/friendly-snippets',
  'nvim-treesitter/nvim-treesitter',
  'stefanandleo/cobol.nvim'
})
local lspconfig = require('lspconfig')
lspconfig.jdtls.setup{}
lspconfig.pyright.setup{}
lspconfig.clangd.setup{}
lspconfig.sqls.setup{}
EOT

chown -R $USER:$USER /home/$USER/.config/nvim

# Aplicativos multimídia e utilitários
pacman -S --noconfirm firefox spotify discord pulseaudio pavucontrol alsa-utils

# Ativar NetworkManager
systemctl enable NetworkManager

EOF

echo "Instalação concluída! Reinicie o computador."
