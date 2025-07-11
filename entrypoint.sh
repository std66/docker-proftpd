#!/bin/bash
set -e

USERS_JSON="/etc/container-config/users.json"

if [ ! -f "$USERS_JSON" ]; then
    echo "No users.json found at $USERS_JSON"
    exit 1
fi

echo "Processing users from $USERS_JSON..."

# Iterate over users
usernames=$(jq -r 'keys[]' "$USERS_JSON")

for username in $usernames; do
    homedir=$(jq -r ".\"$username\".homedir" "$USERS_JSON")
    allow_upload=$(jq -r ".\"$username\".allow_upload" "$USERS_JSON")
    password_secret=$(jq -r ".\"$username\".password_secret // empty" "$USERS_JSON")
    password_plain=$(jq -r ".\"$username\".password // empty" "$USERS_JSON")

    if [ -n "$password_secret" ]; then
        if [ ! -f "$password_secret" ]; then
            echo "Secret file $password_secret not found for user $username"
            exit 1
        fi
        password=$(cat "$password_secret")
    elif [ -n "$password_plain" ]; then
        password="$password_plain"
    else
        echo "No password specified for user $username"
        exit 1
    fi

    echo "Creating user: $username"

    # Create home dir
    mkdir -p "$homedir"
    useradd -d "$homedir" -s /bin/false "$username" || true

    # Set password
    echo "$username:$password" | chpasswd

    # Permissions
    chown -R "$username":"$username" "$homedir"

    if [ "$allow_upload" = "true" ]; then
        chmod u+w "$homedir"
    else
        chmod u-w "$homedir"
    fi
done

echo "Starting proftpd..."
exec /usr/sbin/proftpd --nodaemon
