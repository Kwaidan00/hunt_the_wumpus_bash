#!/bin/bash

# Aleksander Spyra, Wrocław 2018
# The rules from: https://rosettacode.org/wiki/Hunt_The_Wumpus

if [[ $1 == "-h" ]]; then
cat <<EOF
    The rules are:
    The game is set in a cave that consists of a 20 room labyrinth. Each room is connected to 3 other rooms (the cave is modeled after the vertices of a dodecahedron). The objective of the player is to find and kill the horrendous beast Wumpus that lurks in the cave.

The player has 5 arrows. If they run out of arrows before killing the Wumpus, the player loses the game.

In the cave there are:
    One Wumpus
    Two giant bats
    Two bottomless pits

If the player enters a room with the Wumpus, he is eaten by it and the game is lost.
If the player enters a room with a bottomless pit, he falls into it and the game is lost.
If the player enters a room with a giant bat, the bat takes him and transports him into a random empty room.

Each turn the player can either walk into an adjacent room or shoot into an adjacent room.
Whenever the player enters a room, he "senses" what happens in adjacent rooms. The messages are:
    Nearby Wumpus: "You smell something terrible nearby."
    Nearby bat: "You hear a rustling."
    Nearby pit: "You feel a cold wind blowing from a nearby cavern."

When the player shoots, he wins the game if he is shooting in the room with the Wumpus. If he shoots into another room, the Wumpus has a 75% of chance of waking up and moving into an adjacent room: if this is the room with the player, he eats him up and the game is lost. 
EOF
    exit 0
fi

echo -e "Welcome in Hunt The Wumpus\nIf you don't know how to play, run program with -h\n"

declare -a ROOMS_NEIGHBOURS
ROOMS_NEIGHBOURS[1]="2 11 10"
ROOMS_NEIGHBOURS[2]="1 12 3"
ROOMS_NEIGHBOURS[3]="2 13 4"
ROOMS_NEIGHBOURS[4]="3 14 5"
ROOMS_NEIGHBOURS[5]="4 15 6"
ROOMS_NEIGHBOURS[6]="5 16 7"
ROOMS_NEIGHBOURS[7]="6 17 8"
ROOMS_NEIGHBOURS[8]="7 18 9"
ROOMS_NEIGHBOURS[9]="8 19 10"
ROOMS_NEIGHBOURS[10]="1 20 9"
ROOMS_NEIGHBOURS[11]="1 13 19"
ROOMS_NEIGHBOURS[12]="2 20 14"
ROOMS_NEIGHBOURS[13]="3 11 15"
ROOMS_NEIGHBOURS[14]="4 12 16"
ROOMS_NEIGHBOURS[15]="5 13 7"
ROOMS_NEIGHBOURS[16]="6 14 18"
ROOMS_NEIGHBOURS[17]="7 15 19"
ROOMS_NEIGHBOURS[18]="8 16 20"
ROOMS_NEIGHBOURS[19]="9 11 17"
ROOMS_NEIGHBOURS[20]="10 18 12"

function is_value_in_string {
    for value in $2; do
        if [[ $1 -eq $value ]]; then
            return
        fi
    done
    false
}

function get_random_int {
    echo "$(( ($RANDOM % $1) + 1 ))"
}

function get_random_room {
    echo "$(get_random_int 20)"
}

function get_empty_random_room {
    objects="$BAT_1_LOCATION $BAT_2_LOCATION $PIT_1_LOCATION $PIT_2_LOCATION $wumpus_location $player_location"
    room=$(get_random_room)
    while is_value_in_string $room "$objects"; do
        room=$(get_random_room)
    done
    echo $room
}

function is_room_dangerous {
    for dangerous_room in $BAT_1_LOCATION $BAT_2_LOCATION $PIT_1_LOCATION $PIT_2_LOCATION $wumpus_location; do
        for neighbour_of_dangerous_room in ${ROOMS_NEIGHBOURS[$dangerous_room]}; do
            if [[ $1 -eq $neighbour_of_dangerous_room ]]; then
                return
            fi
        done
    done
    false
}

BAT_1_LOCATION=$(get_random_room)
BAT_2_LOCATION=$(get_random_room)
while [[ "$BAT_2_LOCATION" -eq "$BAT_1_LOCATION" ]]; do
    BAT_2_LOCATION=$(get_random_room)
done

PIT_1_LOCATION=$(get_random_room)
PIT_2_LOCATION=$(get_random_room)
while [[ "$PIT_2_LOCATION" -eq "$PIT_1_LOCATION" ]]; do
    PIT_2_LOCATION=$(get_random_room)
done

wumpus_location=$(get_random_room)

player_location=$(get_empty_random_room)
while is_room_dangerous $player_location; do
    player_location=$(get_empty_random_room)
done

number_of_arrows=5
player_status="ALIVE"

while [[ $player_status == "ALIVE" ]]; do
    echo -e "You are in the room number $player_location.\nYou can go to the rooms ${ROOMS_NEIGHBOURS[$player_location]}.\nWhat do you want to do?"
    prompt_text="[$(echo ${ROOMS_NEIGHBOURS[$player_location]} | cut -d ' ' -f1- --output-delimiter=', ') to go, $(echo ${ROOMS_NEIGHBOURS[$player_location]} | cut -d ' ' -f1- --output-delimiter='s, ')s to shoot] "
    read -p "$prompt_text" decision
    destination_room=${decision%%s*}
    while ! is_value_in_string $destination_room "${ROOMS_NEIGHBOURS[$player_location]}"; do
        read -p "$prompt_text" decision
        destination_room=${decision%%s*}
    done
    
    is_player_shooting=${decision: -1}
    if [[ "$is_player_shooting" == "s" ]]; then
        number_of_arrows=$(($number_of_arrows - 1))
        if [[ $destination_room -eq $wumpus_location ]]; then
            player_status="WINNER"
            echo -e '\nCongrats! You have hunted the Wumpus!'
        elif [[ $number_of_arrows -eq 0 ]]; then
            player_status="DEAD"
            echo -e '\nYou have no arrows!\nYou are dead.'
        else
            chance=$(get_random_int 4)
            if [[ $chance -ne 4 ]]; then
                wumpus_move=$(echo "${ROOMS_NEIGHBOURS[$wumpus_location]}" | cut -d " " -f $(get_random_int 3))
                if [[ $wumpus_move -eq $player_location ]]; then
                    player_status="DEAD"
                    echo -e "\nWumpus was awakened. He ate you."
                fi
                wumpus_location=$wumpus_move
            fi
        fi
        echo
    else
        if [[ $destination_room -eq $BAT_1_LOCATION ]]; then
            echo -e "\nThe Giant Bat transport you somewhere..."
            BAT_1_LOCATION=$(get_empty_random_room)
            player_location=$BAT_1_LOCATION
        elif [[ $destination_room -eq $BAT_2_LOCATION ]]; then
            echo -e "\nThe Giant Bat transport you somewhere..."
            BAT_2_LOCATION=$(get_empty_random_room)
            player_location=$BAT_2_LOCATION
        elif [[ $destination_room -eq $PIT_1_LOCATION || $destination_room -eq $PIT_2_LOCATION ]]; then
            echo -e "\nYou fall into the pit. The game is lost."
            player_status="DEAD"
        elif [[ $destination_room -eq $wumpus_location ]]; then
            echo -e "\nYou are eaten by wumpus and the game is lost."
            player_status="DEAD"
        else
            echo
            destination_room_neighbours="${ROOMS_NEIGHBOURS[$destination_room]}"
            if is_value_in_string $BAT_1_LOCATION "$destination_room_neighbours" || is_value_in_string $BAT_2_LOCATION "$destination_room_neighbours"; then
                echo "You hear a rustling."
            fi
            if is_value_in_string $PIT_1_LOCATION "$destination_room_neighbours" || is_value_in_string $PIT_2_LOCATION "$destination_room_neighbours"; then
                echo "You feel a cold wind blowing from a nearby cavern."
            fi
            if is_value_in_string $wumpus_location "$destination_room_neighbours"; then
                echo "You smell something terrible nearby."
            fi
            player_location=$destination_room
        fi
    fi
done
