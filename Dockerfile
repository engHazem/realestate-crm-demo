# EspoCRM real estate client demo (web + background jobs in one container).
FROM espocrm/espocrm:10.0.11-apache

COPY demo/custom/ /usr/src/demo/custom/
COPY demo/client-custom/ /usr/src/demo/client-custom/
COPY demo/tab-list.json /usr/src/demo/tab-list.json
COPY start.sh db-has-install.php /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

ENTRYPOINT ["start.sh"]
CMD ["apache2-foreground"]
