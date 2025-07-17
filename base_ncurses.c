#include <ncurses.h>
#include "base_ncurses.h"

void open(int get_key) {
   initscr();
   if(get_key) {
	  raw();
	  keypad(stdscr, TRUE);
	  noecho();
   }
}

void close() {
   refresh();
   getch();
   endwin();
}
