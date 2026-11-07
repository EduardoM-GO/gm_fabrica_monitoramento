enum SyncStatusEnum {
  pending, // 0: Novo registro, aguardando envio para o Supabase
  synced, // 1: Sincronizado com sucesso
  updating, // 2: Foi alterado localmente (ex: lote fechou) e precisa atualizar na nuvem
  error, // 3: Falha na última tentativa de envio (Supabase fora do ar, timeout)
}
