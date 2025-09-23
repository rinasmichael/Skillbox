 - Передаем клиенту скрипт(<https://github.com/rinasmichael/Skillbox/blob/main/Scripts/Client/gen_cert_client.sh>) установки easyrsa и создание запроса 

 - Получаем на админской машине этот req файл(кладем его в ~/clients/reqs)  и запускаем скрипт sign_cert_and_createfiles.sh(<https://github.com/rinasmichael/Skillbox/blob/main/Scripts/Client/sign_cert_and_createfiles.sh>) . 

 - Отправляем base.conf,ca.crt,ta.key,$client.crt и скрипт генерации ovpn файла(ovpn.sh)  и запуска openvpn-client клиенту 

 - Клиенту нужно при запуске скрипта ввести адрес клиента, который он раньше вводил, адрес VPN-сервера, который ему сообщили админы.
