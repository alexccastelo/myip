#!/bin/bash

CONFIG="$HOME/.myip/config"
LAST_IP_FILE="$HOME/.myip/last_ip"
LOG="$HOME/.myip/myip.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Verifica se o arquivo de config existe
if [ ! -f "$CONFIG" ]; then
  echo "[$TIMESTAMP] Erro: arquivo de config não encontrado em $CONFIG" >> "$LOG"
  exit 1
fi

source "$CONFIG"

# Verifica se as variáveis necessárias estão definidas
if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "[$TIMESTAMP] Erro: TELEGRAM_TOKEN ou TELEGRAM_CHAT_ID não definidos em $CONFIG" >> "$LOG"
  exit 1
fi

# Busca IP atual (com retry para aguardar rede após boot/wake)
MAX_RETRIES=5
RETRY_WAIT=10
CURRENT_IP=""

for i in $(seq 1 $MAX_RETRIES); do
  CURRENT_IP=$(curl -s --max-time 10 https://api.ipify.org)
  [ -n "$CURRENT_IP" ] && break
  echo "[$TIMESTAMP] Tentativa $i/$MAX_RETRIES: rede indisponível, aguardando ${RETRY_WAIT}s..." >> "$LOG"
  sleep $RETRY_WAIT
done

if [ -z "$CURRENT_IP" ]; then
  echo "[$TIMESTAMP] Erro: não foi possível obter o IP após $MAX_RETRIES tentativas" >> "$LOG"
  exit 1
fi

# Lê último IP registrado
LAST_IP=$(cat "$LAST_IP_FILE" 2>/dev/null)

if [ "$CURRENT_IP" != "$LAST_IP" ]; then
  ANTERIOR="${LAST_IP:-'(nenhum)'}"
  MSG="IP publico mudou!%0AAnterior: ${ANTERIOR}%0AAtual: ${CURRENT_IP}"

  RESPONSE=$(curl -s --max-time 10 \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}&text=${MSG}")

  if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "[$TIMESTAMP] IP mudou: ${LAST_IP:-'(nenhum)'} -> $CURRENT_IP. Alerta enviado." >> "$LOG"
  else
    echo "[$TIMESTAMP] IP mudou: ${LAST_IP:-'(nenhum)'} -> $CURRENT_IP. Falha ao enviar alerta: $RESPONSE" >> "$LOG"
  fi

  echo "$CURRENT_IP" > "$LAST_IP_FILE"
else
  MSG="IP publico sem mudanca.%0AAtual: ${CURRENT_IP}"
  curl -s --max-time 10 \
    "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}&text=${MSG}" > /dev/null
  echo "[$TIMESTAMP] IP sem mudança: $CURRENT_IP. Notificação enviada." >> "$LOG"
fi
