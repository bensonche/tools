#!/bin/bash

cp bashrc.bash ~/.custom_bashrc
cp customprompt.bash ~/.custom_prompt

chmod 777 ~/.custom_bashrc
chmod 777 ~/.custom_prompt

CMD="source ~/.custom_bashrc"
grep -q "$CMD" ~/.bashrc
if [ $? -ne 0 ]
then
	echo "" >> ~/.bashrc
	echo $CMD >> ~/.bashrc
fi

cp vimrc ~/.vimrc
