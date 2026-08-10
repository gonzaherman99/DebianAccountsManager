#! /bin/bash

FOLDER="AccountManagmentSys"


folderfind=$(find /tmp -maxdepth 1 -name "$FOLDER" -type d -printf 1 -quit)
folderfind=${folderfind:-0}

if [ "$folderfind" != "1" ]; then
    mkdir -p /tmp/"$FOLDER"
else
    echo "Directory already created."
fi


on_handle_error() {
    local output
    output=$("$@" 2>&1)
    local status=$?

    if [ "$status" -ne 0 ]; then
        whiptail --title "Error" --msgbox "$output , exit with status: $status"  12 78
    fi


    return "$status"
}

inputbox_wrapper() {
    local title=$1
    local local_title=$2
    local placeholer=$3

    whiptail --inputbox "$local_title" 8 39 "$placeholer" --title "$title" 3>&1 1>&2 2>&3
}

failed_non_value_entered() {
     whiptail --msgbox "No value entered."  8 78
}

while true; do

MENU=$(whiptail --title "Account Managment System" --menu "Choose an option" 27 78 16 \
"0" "Exit" \
"1" "Show all users (export to file optional)" \
"2" "Show last password change (specific user or all)" \
"3" "Show users closest to password expiration" \
"4" "Show users with their groups" \
"5" "Show locked users" \
"6" "Lock a user account" \
"7" "Unlock a user account" \
"8" "Show accounts with root privileges (UID 0)" \
"9" "Show inactive users (never logged in)" \
"10" "Change a user login shell" \
"11" "See/Update a user account details" \
"12" "Displays user details" \
"13" "Add a user" \
"14" "Delete a user" \
"15" "Update a user's group(s)" \
"16" "Show failed login attempts" \
3>&1 1>&2 2>&3)




exitstatus=$?

if [[ "$CHOICE" = "Quit" || "$exitstatus" != 0  ]]; then
    
    echo "See you later!"
    break

elif [ "$MENU" = "1" ]; then


    on_handle_error echo "$(cut -d: -f1 /etc/passwd)" > /tmp/"$FOLDER"/all_users
                  
    whiptail --textbox --scrolltext /tmp/"$FOLDER"/all_users 30 80

    
elif [ "$MENU" = "2" ]; then

    echo "$(sudo passwd -S -a | cut -d " " -f 1,3)" > /tmp/"$FOLDER"/last_password

     whiptail --textbox --scrolltext /tmp/"$FOLDER"/last_password 30 80

elif [ "$MENU" = "3" ]; then

    on_handle_error echo "$cut -f 1 -d: /etc/passwd | xargs -n 100 -I {} bash -c " echo -e '\n{}' ; sudo chage -l {} | sed -n 2p"" > tee /tmp/"$FOLDER"/password_expirations

    whiptail --textbox --scrolltext /tmp/"$FOLDER"/password_expirations 30 80


elif [ "$MENU" = "4" ]; then

     on_handle_error cut -d: -f1 /etc/passwd | xargs groups > /tmp/"$FOLDER"/users_groups

     whiptail --textbox --scrolltext /tmp/"$FOLDER"/users_groups 30 80 

elif [ "$MENU" = "5" ]; then

    on_handle_error sudo passwd -S -a | grep L | cut -d " " -f1 > /tmp/"$FOLDER"/locked_users

    whiptail --textbox --scrolltext /tmp/"$FOLDER"/locked_users 30 80 


elif [ "$MENU" = "6" ]; then

        USERNAME=$(inputbox_wrapper "Lock a user"  "Type the username below.")

        on_handle_error usermod -L "$USERNAME" 2>&1
        
elif [ "$MENU" = "7" ]; then

    while true; do

       USERNAME=$(inputbox_wrapper "Unlock a user" "Type the username below.")

        exitstatus=$?

        if [[ -n "$USERNAME" ]]; then
            on_handle_error usermod --unlock "$USERNAME" 2>&1
            break;
        elif [[ "$exitstatus" != 0 ]]; then
            echo "User selected cancel."
            break;
        else
           failed_non_value_entered
        fi
    
    done

elif [ "$MENU" = "8" ]; then

    GETINFO=$(on_handle_error getent group sudo | awk -F: '{print $4}' |  tr "," " ") 

    if [[ -n "$GETINFO" ]]; then

      echo "$GETINFO" > /tmp/"$FOLDER"/sudoprivileges

      whiptail --textbox /tmp/"$FOLDER"/sudoprivileges 12 80
    else
        whiptail --msgbox "No users found with sudo privileges" 8 78
    fi


elif [ "$MENU" = "9" ]; then

    on_handle_error touch /tmp/"$FOLDER"/neverloggedin

    for user in $(cut -d: -f1 /etc/passwd); do
        if ! lastlog -u $user | grep -q "Never logged in"; then
        continue
    fi


    echo "$user has never logged in" >> /tmp/"$FOLDER"/neverloggedin

    done

     whiptail --textbox /tmp/"$FOLDER"/neverloggedin 12 80

elif [ "$MENU" = "10" ]; then


    while true; do

        USERNAME=$(inputbox_wrapper "Change a login shell" "Type the username below.")

        

        if [[ -n "$USERNAME" ]]; then
            on_handle_error sudo chsh "$USERNAME"
            break;
        elif [[ "$exitstatus" != 0 ]]; then
            echo "User selected cancel."
            break;
        else
           failed_non_value_entered
        fi
    
    done

elif [ "$MENU" = "11" ]; then

    while true; do

        USERNAME=$(inputbox_wrapper "Account details" "Type the username below.")

        exitstatus=$?

        if [[ -n "$USERNAME" ]]; then
            on_handle_error sudo chfn "$USERNAME"
            break;
        elif [[ "$exitstatus" != 0 ]]; then
            echo "User selected cancel."
            break;
        else
           failed_non_value_entered
        fi
    
    done
   

elif [ "$MENU" = "12" ]; then

    while true; do

        USERNAME=$(inputbox_wrapper "User details" "Type the username below.")

        exitstatus=$?

        if [[ -n "$USERNAME" ]]; then
            on_handle_error sudo finger "$USERNAME" | less
            break;
        elif [[ "$exitstatus" != 0 ]]; then
            echo "User selected cancel."
            break;
        else
           failed_non_value_entered
        fi
    
    done

elif [ "$MENU" = "13" ]; then

    USERNAME=$(inputbox_wrapper "Add a user" "Type the username to create below.")

    sudo useradd "$USERNAME" 

elif [ "$MENU" = "14" ]; then

    USERNAME=$(inputbox_wrapper "Delete a user" "Type the username below.")

    on_handle_error sudo userdel "$USERNAME"

elif [ "$MENU" = "15" ]; then

    while true; do

        USERNAME=$(inputbox_wrapper "User group change" "Type the username below.")

        if [[ -z "$USERNAME" ]]; then
             failed_non_value_entered
        else
            GROUP=$(inputbox_wrapper "User group change" "Type the group below.")

            exitstatus=$?

            if [[ -n "$GROUP" ]]; then
                on_handle_error sudo usermod "$USERNAME" -g "$GROUP"
                break;
            elif [[ "$exitstatus" != 0 ]]; then
                echo "User selected cancel."
                break;
            else
                failed_non_value_entered
            fi
        fi
    done

elif [[ "$MENU" = "16" ]]; then

    sudo lastb | less

fi

done