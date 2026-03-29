FROM wordpress:latest

# Gerekli PHP eklentilerini veya güncellemeleri buraya ekleyebilirsin
# Şimdilik standart tutuyoruz ama yapı hazır kalsın
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    && docker-php-ext-install gd

# WordPress dosyalarının izinlerini ayarla (Senior dokunuşu)
RUN chown -R www-data:www-data /var/www/html