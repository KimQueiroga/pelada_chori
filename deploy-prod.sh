#!/bin/bash

# ⚙️ Configurações
S3_BUCKET="app.peladadochori.com"
CLOUDFRONT_DIST_ID="E3ILIDL653UA2W"

# ✅ Etapa 1 - Build Web com ENV=homol
echo "🔨 Gerando build Flutter Web com ambiente de Produçao..."
flutter build web --release --dart-define=ENV=prod

# ✅ Etapa 2 - Sincronizando com S3 (substitui e deleta arquivos antigos)
echo "📤 Enviando arquivos para o S3..."
aws s3 sync build/web s3://$S3_BUCKET --delete

# ✅ Etapa 3 - Invalidação do cache no CloudFront
echo "🚀 Invalidando cache no CloudFront..."
aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DIST_ID --paths "/*"

echo "✅ Deploy concluído com sucesso!"
