#!/bin/sh

# This script brought to you by a shitpost by [deleted] on /r/linuxmasterrace
# https://www.reddit.com/r/linuxmasterrace/comments/84zkr4/id_just_like_to_interject_for_a_moment_what_youre/dvuqfvy/?context=1

stallman="I'd just like to interject for moment. What you're refering to as \
Linux, is in fact, GNU/Linux, or as I've recently taken to calling it, GNU \
plus Linux. Linux is not an operating system unto itself, but rather another \
free component of a fully functioning GNU system made useful by the GNU \
corelibs, shell utilities and vital system components comprising a full OS as \
defined by POSIX.

Many computer users run a modified version of the GNU system every day, \
without realizing it. Through a peculiar turn of events, the version of GNU \
which is widely used today is often called Linux, and many of its users are \
not aware that it is basically the GNU system, developed by the GNU Project.

There really is a Linux, and these people are using it, but it is just a part \
of the system they use. Linux is the kernel: the program in the system that \
allocates the machine's resources to the other programs that you run. The \
kernel is an essential part of an operating system, but useless by itself; it \
can only function in the context of a complete operating system. Linux is \
normally used in combination with the GNU operating system: the whole system \
is basically GNU with Linux added, or GNU/Linux. All the so-called Linux \
distributions are really distributions of GNU/Linux!"

gnu=$1
linux=$2

# Prevent re-evaluating of "GNU"s in the first argument.
gnu_count=$(echo $gnu | tr ' ' '\n' | grep "GNU" | wc -l)
if [ "$gnu_count" -eq 0 ]
then
    gnu_skip=
else
    gnu_skip=$((2 + $gnu_count))
fi

gnu_slash=$(echo $gnu | tr ' ' '/' | head -c-1)
gnu_plus=$(echo $gnu_slash | sed "s|/| plus |g")

echo "$stallman" | \
    sed -z \
    -e "s|GNU|$gnu_slash|" \
    -e "s|GNU plus Linux|$gnu_plus plus $linux|" \
    -e "s|GNU|$gnu_slash|${gnu_skip}g" \
    -e "s|Linux|$linux|g"
