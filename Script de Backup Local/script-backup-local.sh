#!/bin/bash

#Obs: é preciso ter os pacotes zip, tar e ftp instalados!

#Formato da data
data=$(date +"%d_%m_%Y") # Nesse exemplo a data está no formato dia, mês e ano

#Localização inicial dos logs
log_location="/var/log"

#Função que irá compactar as pastas
criador_backup(){

    clear
    echo "Informe o caminho da pasta que deseja fazer backup"
    read -p "Por exemplo /root/teste: " pastaBackup

    echo

    echo "Informe o caminho para salvar o backup"
    read -p "Por exemplo /tmp: " destinoBackup

    echo

    echo "Informe a pasta para salvar o log"
    read -p "Por exemplo /root: " log
    log_backup="$log_location/log-backup-$data.txt"
    
    echo
    
    echo "Escolha o tipo de compactação"
    echo "1 - .tar.gz"
    echo "2 - .tar"
    echo "3 - .zip"

    read compactacao

    #Identifica o tipo de compactação para executar o comando correto
    case $compactacao in
        1) compactacao="tar.gz" ;;
        2) compactacao="tar" ;;
        3) compactacao="zip" ;;
        *) echo "Opção inválida" ;;
    esac

    #Caso queira alterar o nome do seu backup, altere a variável abaixo, caso queira que ela tenha o nome de sua máquina coloque $hostname
    arquivo_backup="$destinoBackup/backup-$data.$compactacao"
    echo "Criando backup em $arquivo_backup" >> "$log_backup" 2>&1

    #Será feito a compactação de acordo com a escolha do tipo de compactação
    if [ $compactacao = "zip" ]; then
        zip -r $arquivo_backup $pastaBackup >> "$log_backup" 2>&1
    elif [ $compactacao = "tar" ]; then
        tar -cf $arquivo_backup $pastaBackup >> "$log_backup" 2>&1
    else
        tar -czf $arquivo_backup $pastaBackup >> "$log_backup" 2>&1
    fi

    #$? é uma variável contém o resultado do comando executado recentemente, que no caso foi o comando tar. Se o comando foi executado com sucesso, ele retornará 0 caso contrário retornará um valor diferente.
    if [ $? -ne 0 ]; then
        echo "Falha ao criar o arquivo de backup." >> "$log_backup" 2>&1
        echo "Falha ao criar o arquivo de backup."
        echo "Para mais informações consulte o log em $log_backup"
        echo "Retornando ao menu principal"
        sleep 3
    else
        echo "Backup criado com sucesso!" >> "$log_backup" 2>&1
        echo "Backup criado com sucesso!"
        echo "Retornando ao menu principal"
        sleep 3
    fi

    menu_principal
}

#Função que irá descompactar as pastas
restaurar_backup(){
    clear

    echo "Atenção: O arquivo de backup deve estar compactado no formato .zip, .tar ou .tar.gz"
    echo "Caso for .zip tenha em mente que irá precisar do package zip"

    echo

    echo "Informe o caminho absoluto do arquivo de backup"
    read -p "Por exemplo /root/backup.tar.gz: " arquivoBackup

    echo

    echo "Informe o caminho para salvar o backup"
    read -p "Por exemplo /tmp: " destinoBackup

    echo

    echo "Informe a pasta para salva o log"
    read -p "Por exemplo /root: " log
    log_restaurar="$log_location/log-restauracao-$data.txt"

    echo

    #Identifica o tipo de compactação para executar o comando correto
    tipoCompactacao=$(echo $arquivoBackup | cut -d'.' -f2,3)

    if [ $tipoCompactacao = "zip" ]; then
        echo "Extraindo em $destinoBackup" >> "$log_restaurar" 2>&1
        unzip $arquivoBackup -d $destinoBackup
    elif [ $tipoCompactacao = "tar" ]; then
        echo "Extraindo em $destinoBackup" >> "$log_restaurar" 2>&1
        tar -xf $arquivoBackup -C $destinoBackup
    else
        echo "Extraindo em $destinoBackup" >> "$log_restaurar" 2>&1
        tar -xzf $arquivoBackup -C $destinoBackup
    fi

    if [ $? -ne 0 ]; then
        echo "Falha ao extrair o arquivo." >> "$log_restaurar" 2>&1
        echo "Falha ao extrair o arquivo."
        echo "Para mais informações consulte o log em $log_restaurar"
        echo "Retornando ao menu principal"
        sleep 3
    else
        echo "Extração bem sucedida!" >> "$log_restaurar" 2>&1
        echo "Extração bem sucedida!"
        echo "Retornando ao menu principal"
        sleep 3
    fi

}

# Função para enviar o backup para o FTP
enviar_backup_ftp(){

    echo "Informe o caminho absoluto do arquivo que deseja enviar via FTP."
    read -p "Por exemplo /root/backup.zip: " backup_file

    echo "Informe a pasta para salva o log"
    read -p "Por exemplo /root: " log
    log_ftp="$log_location/log-ftp-$data.txt"

    # Verifica se o arquivo local existe antes de enviar;
    if [ ! -f "$backup_file" ]; then
        echo "Erro: O arquivo $backup_file não foi encontrado." >> "$log_ftp" 2>&1
        echo "Erro: O arquivo $backup_file não foi encontrado."
        echo "Para mais informações consulte o log em $log_ftp"
        sleep 3
        menu_principal
    fi

    read -p "Informe o host do FTP: " FTP_HOST
    read -p "Informe o usuário do FTP: " FTP_USER
    read -p "Informe a senha do FTP: " FTP_PASS
    read -p "Informe o diretório do FTP: " FTP_DIR

    echo "Enviando backup para o FTP..." >> "$log_ftp" 2>&1
    
    cd $(dirname $backup_file)
    # Envio do arquivo via FTP
    # Devido o uso do EOF a identação ficará justificada a esquerda
ftp -inv $FTP_HOST <<EOF >> "$log_ftp" 2>&1
user $FTP_USER $FTP_PASS
bin
cd $FTP_DIR
put $(basename $backup_file)
bye
EOF

    # Verifica se o upload foi bem-sucedido"
    if grep -q "226" "$log_ftp"; then
        echo "Upload concluído!" >> "$log_ftp" 2>&1
        read -p "Deseja excluir o arquivo local? (s/n): " excluir
        if [ $excluir = "s" ]; then
            rm -rf $backup_file
            echo "Arquivo local $backup_file foi excluído." >> "$log_ftp" 2>&1
        fi
        menu_principal
    else
        echo "Falha no Upload! Arquivo de backup em $backup_file" >> "$log_ftp" 2>&1
        echo "Falha no Upload! Arquivo de backup em $backup_file"
        echo "Para mais informações consulte o log em $log_ftp"
        sleep 3
        menu_principal
    fi

}

menu_principal(){
    clear
    echo "Bem vindo ao script para realizar backup de pastas"
    echo "1 - Criar Backup"
    echo "2 - Restaurar Backup"
    echo "3 - Enviar Backup via FTP"
    echo "9 - Configurações"
    echo "0 - Sair"
    echo
    echo "Localização dos logs: $log_location"

    #Verifica se os pacotes necessários estão instalados
    verificar_pacote zip
    verificar_pacote tar
    verificar_pacote ftp
    echo "Obs: é necessário ter os pacotes zip, tar e ftp instalados!"
    
    echo
    read -p "Digite a opção: " opcao
    
    case $opcao in
        1) criador_backup ;;
        2) restaurar_backup ;;
        3) enviar_backup_ftp ;;
        9) configuracoes ;;
        0) exit ;;
        *) echo "Opção inválida" ;;
    esac
}

configuracoes() {
    clear
    echo "Configurações"
    echo "1 - Alterar localização dos logs"
    echo "2 - Instalar pacotes necessários"
    echo "0 - Voltar"
    echo
    read -p "Digite a opção: " opcao
    case $opcao in
        1) alterar_localizacao_logs ;;
        2) install_packages ;;
        0) menu_principal ;;
        *) echo "Opção inválida" ;;
    esac
}

alterar_localizacao_logs() {
    clear
    echo "Informe o caminho para salvar os logs"
    read -p "Por exemplo /root: " log_location
    echo "Localização dos logs alterada para $log_location"
    sleep 2
    menu_principal
}

install_packages() {
    clear
    #Essa variável irá verificar qual é o sistema operacional
    OS=$(lsb_release -si)    
    echo "Foi verificado a sua OS é $OS"
    echo "Instalando os pacotes zip, tar e ftp ..."
    #Será instalado o pacote de acordo com a sua distribuição
    case $OS in
        Ubuntu|Debian) sudo apt install zip tar ftp -y ;;
        CentOS|Fedora) sudo yum install zip tar ftp -y ;;
        *) echo "Sistema operacional não suportado" ;;
    esac
    sleep 2
    menu_principal
}

verificar_pacote(){
   if ! which "$1" > /dev/null 2>&1; then
         echo "Não foi encontrado o pacote $1!"
    fi
}

menu_principal
