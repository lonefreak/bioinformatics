tel() { if [[ -z "$1" ]]; then echo "tel <host alias>"; else telnet $(grep "$1" ~/.telnetiplist | cut -d':' -f2); fi }
tel_add() { if [ -z "$1" ] || [ -z "$2" ]; then echo "tel_add <host alias> <host ip>"; else echo "$1:$2" >> ~/.telnetiplist; fi }
tel_check() { nick=$(grep "$1" ~/.telnetiplist | cut -d':' -f2); if [ -z $1 ] || [ -z $nick ]; then echo "Host alias not found"; else echo "$nick"; fi }
tel_remove() { if [[ -z "$1" ]]; then echo "tel_remove <host alias> OR tel_remove <host ip>"; else sed -i -e '/'"$1"'/d' ~/.telnetiplist; fi }
