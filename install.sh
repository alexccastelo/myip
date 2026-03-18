#!/bin/bash

set -e

MYIP_DIR="$HOME/.myip"
CONFIG_FILE="$MYIP_DIR/config"
PLIST_NAME="com.alexccastelo.myip.plist"
PLIST_SRC="$(dirname "$0")/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "==> Criando diretório $MYIP_DIR..."
mkdir -p "$MYIP_DIR"

# Cria arquivo de config se não existir
if [ ! -f "$CONFIG_FILE" ]; then
  echo "==> Criando $CONFIG_FILE..."
  cat > "$CONFIG_FILE" <<EOF
TELEGRAM_TOKEN=seu_token_aqui
TELEGRAM_CHAT_ID=seu_chat_id_aqui
EOF
  echo "    ATENÇÃO: edite $CONFIG_FILE com seu token e chat_id antes de continuar."
else
  echo "==> Config já existe em $CONFIG_FILE, mantendo."
fi

# Torna o script principal executável
echo "==> Tornando check_ip.sh executável..."
chmod +x "$(dirname "$0")/check_ip.sh"

# Copia o plist para LaunchAgents
echo "==> Instalando launchd agent..."
cp "$PLIST_SRC" "$PLIST_DEST"

# Descarrega versão anterior se existir
if launchctl list | grep -q "com.alexccastelo.myip"; then
  echo "==> Descarregando agente anterior..."
  launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Carrega o agente
echo "==> Carregando agente launchd..."
launchctl load "$PLIST_DEST"

echo ""
echo "✓ Instalação concluída!"
echo ""
echo "Próximos passos:"
echo "  1. Edite $CONFIG_FILE com seu TELEGRAM_TOKEN e TELEGRAM_CHAT_ID"
echo "  2. Teste manualmente: bash $(dirname "$0")/check_ip.sh"
echo "  3. Verifique os logs: cat $HOME/.myip/myip.log"
echo "  4. Force execução agora: launchctl start com.alexccastelo.myip"
