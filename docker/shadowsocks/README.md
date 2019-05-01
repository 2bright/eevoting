# shadowsocks server
you should have a running shadowsocks server.

https://www.textarea.com/ExpectoPatronum/shiyong-shadowsocks-kexue-shangwang-265/

# config sslocal.json
create and edit sslocal.json

`cp sslocal.json.example sslocal.json`

# use in docker container

## start shadowsocks client
enter docker container, then run the following command.

`source ssctl start`

## test
wget google.com

## stop shadowsocks client
`source ssctl stop`
