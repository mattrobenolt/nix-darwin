# nix-darwin Configuration

Declarative system configuration for macOS via [nix-darwin](https://github.com/LnL7/nix-darwin).

## Bootstrap: Setting Up a New Mac

### 1. Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart your terminal after installation.

### 2. Clone This Repository

```bash
git clone https://github.com/mattrobenolt/nix-darwin.git ~/.config/nix-darwin
cd ~/.config/nix-darwin
```

### 3. Create System Symlink

```bash
sudo ln -s ~/.config/nix-darwin /etc/nix-darwin
```

### 4. Apply Configuration

```bash
sudo darwin-rebuild switch
```

### 5. Restart Terminal

Quit and reopen your terminal for all changes to take effect.
