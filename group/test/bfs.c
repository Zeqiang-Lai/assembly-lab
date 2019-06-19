#include <stdio.h>
#define INF 1000000

int dir_x[4] = {0,0,1,-1};
int dir_y[4] = {1,-1,0,0}

int qx[Q_LEN];
int qy[Q_LEN];
int head=0,tail=0;

int dis[MAX_X][MAX_Y];
int visit[MAX_X][MAX_Y];

char dir2c[4] = {'s', 'w', 'd', 'a'};
char cur_dir;

void ai_init()
{
    head = 0;
    tail = 0;
    for(int i=0; i<MAX_X*MAX_Y; ++i) {
        *(dis+i) = INF;
        *(visit+i) = INF;
    }
}

void ai_compute_path()
{
    ai_init();
    dis[food_x][food_y] = 0;
    qx[tail] = food_x;
    qy[tail] = food_y;
    tail = (tail+1)%Q_LEN;

    int tx, ty;
    int tx2, ty2;
    while(head != tail)
    {
        tx = qx[head];
        ty = qy[head];
        for(int i=0; i<4; ++i) {
            tx2 = tx+dir_x[i];
            ty2 = ty+dir_y[i];
            if(map[tx2][ty2] == 0 && visit[tx2][ty2] == 0) {
                dis[tx2][ty2] = dis[tx][ty] + 1;
                qx[tail] = tx2;
                qy[tail] = ty2;
                tail = (tail+1) % Q_LEN;
                visit[tx2][ty2] = 1;
            }
        }
        head = (head+1) % Q_LEN;
    }
}

void ai_choose_dir()
{
    int min = INF;
    int dir = 0;
    for(int i=0; i<4; ++i) {
        tx2 = tx+dir_x[i];
        ty2 = ty+dir_y[i];
        if(dis[tx2][ty2] < min) {
            min = dis[tx2][ty2];
            dir = i;
        }
    }
    cur_dir = dir2c[dir];
}