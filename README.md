# rmn-adv

Короткий вспомогательный скрипт для первичной подготовки сервера под RemnaNode.

`server-preinstall.sh` добавляет публичный SSH-ключ в `authorized_keys`, отключает парольную SSH-аутентификацию, проверяет и перезапускает `sshd`, а затем запускает удаленный установщик RemnaNode.

Исходный репозиторий удаленного установщика: <https://github.com/DigneZzZ/remnawave-scripts>

## Запуск

Если файл уже скачан на сервер:

```sh
sudo sh server-preinstall.sh
```

Запуск напрямую с GitHub:

```sh
curl -fsSL https://raw.githubusercontent.com/Vitalick/rmn-adv/refs/heads/main/server-preinstall.sh | sudo sh
```

Или через `wget`:

```sh
wget -qO- https://raw.githubusercontent.com/Vitalick/rmn-adv/refs/heads/main/server-preinstall.sh | sudo sh
```

Скрипт нужно запускать от `root`. Перед запуском убедитесь, что у вас есть рабочий публичный SSH-ключ: после отключения парольного входа доступ к серверу будет возможен только по ключу.
