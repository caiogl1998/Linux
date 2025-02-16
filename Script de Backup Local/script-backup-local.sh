#!/bin/bash

#tar czf $dest/$archive_file $backup_files

#Formato da data
data=$(date +"%d_%m_%Y") # Nesse exemplo a data está no formato dia, mês e ano


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
    log="$log/log-backup-$data.txt"


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
    echo "Criando backup em $arquivo_backup" >> "$log" 2>&1

    #Será feito a compactação de acordo com a escolha do tipo de compactação
    if [ $compactacao = "zip" ]; then
        zip -r $arquivo_backup $pastaBackup >> "$log" 2>&1
    elif [ $compactacao = "tar" ]; then
        tar -cf $arquivo_backup $pastaBackup >> "$log" 2>&1
    else
        tar -czf $arquivo_backup $pastaBackup >> "$log" 2>&1
    fi


    #$? é uma variável contém o resultado do comando executado recentemente, que no caso foi o comando tar. Se o comando foi executado com sucesso, ele retornará 0 caso contrário retornará um valor diferente.
    if [ $? -ne 0 ]; then
        echo "Falha ao criar o arquivo de backup." >> "$log" 2>&1
        echo "Falha ao criar o arquivo de backup."
        echo "Retornando ao menu principal"
        sleep 5
    else
        echo "Backup criado com sucesso!" >> "$log" 2>&1
        echo "Backup criado com sucesso!"
        echo "Retornando ao menu principal"
        sleep 5
    fi

    

    menu_principal
}



# #Função que irá descompactar as pastas
restaurar_backup(){
    clear

    echo "Atenção: O arquivo de backup deve estar compactado no formato .zip, .tar ou .tar.gz"
    echo "Caso for .zip tenha em mente que irá precisar do package zip"

    echo

    echo "Informe o caminho do arquivo de backup"
    read -p "Por exemplo /root/backup.tar.gz: " arquivoBackup

    echo

    echo "Informe o caminho para salvar o backup"
    read -p "Por exemplo /tmp: " destinoBackup

    echo

    echo "Informe a pasta para salva o log"
    read -p "Por exemplo /root: " log
    log="$log/log-restauracao-$data.txt"

    echo

    #Identifica o tipo de compactação para executar o comando correto
    tipoCompactacao=$(echo $arquivoBackup | cut -d'.' -f2,3)

    if [ $tipoCompactacao = "zip" ]; then
        echo "Extraindo em $destinoBackup" >> "$log" 2>&1
        unzip $arquivoBackup -d $destinoBackup
    elif [ $tipoCompactacao = "tar" ]; then
        echo "Extraindo em $destinoBackup" >> "$log" 2>&1
        tar -xf $arquivoBackup -C $destinoBackup
    else
        echo "Extraindo em $destinoBackup" >> "$log" 2>&1
        tar -xzf $arquivoBackup -C $destinoBackup
    fi

    if [ $? -ne 0 ]; then
        echo "Falha ao extrair o arquivo." >> "$log" 2>&1
        echo "Falha ao extrair o arquivo."
        echo "Retornando ao menu principal"
        sleep 5
    else
        echo "Extração bem sucedida!" >> "$log" 2>&1
        echo "Extração bem sucedida!"
        echo "Retornando ao menu principal"
        sleep 5
    fi

}

# Função para enviar o backup para o FTP
enviar_backup_ftp(){

    echo "Informe o caminho absoluto do arquivo que deseja enviar via FTP."
    read -p "Por exemplo /root/backup.zip: " backup_file

    echo "Informe a pasta para salva o log"
    read -p "Por exemplo /root: " log
    log="$log/log-ftp-$data.txt"

    # Verifica se o arquivo local existe antes de enviar;
    if [ ! -f "$backup_file" ]; then
        echo "Erro: O arquivo $backup_file não foi encontrado." >> "$log" 2>&1
        exit 1
    fi

    read -p "Informe o host do FTP: " FTP_HOST
    read -p "Informe o usuário do FTP: " FTP_USER
    read -p "Informe a senha do FTP: " FTP_PASS
    read -p "Informe o diretório do FTP: " FTP_DIR

    echo "Enviando backup para o FTP..." >> "$log" 2>&1
    
    cd $(dirname $backup_file)
    # Envio do arquivo via FTP
    # Devido o uso do EOF a identação ficará justificada a esquerda
ftp -inv $FTP_HOST <<EOF >> "$log" 2>&1
user $FTP_USER $FTP_PASS
bin
cd $FTP_DIR
put $(basename $backup_file)
bye
EOF

    # Verifica se o upload foi bem-sucedido e exclui o backup local em caso de sucesso
    if grep -q "226" "$log"; then
        echo "Upload concluído!" >> "$log" 2>&1
        read -p "Deseja excluir o arquivo local? (s/n): " excluir
        if [ $excluir = "s" ]; then
            rm -rf $backup_file
            echo "Arquivo local $backup_file foi excluído." >> "$log" 2>&1
        fi
        exit 0
    else
        echo "Falha no Upload! Arquivo de backup em $backup_file" >> "$log" 2>&1
        exit 1
    fi

}



menu_principal(){
    clear
    echo "Bem vindo ao script para realizar backup de pastas"
    echo "1 - Criar Backup"
    echo "2 - Restaurar Backup"
    echo "3 - Enviar Backup via FTP"
    echo "0 - Sair"
    echo
    read -p "Digite a opção: " opcao
    case $opcao in
        1) criador_backup ;;
        2) restaurar_backup ;;
        3) enviar_backup_ftp ;;
        0) exit ;;
        *) echo "Opção inválida" ;;
    esac
}

menu_principal
