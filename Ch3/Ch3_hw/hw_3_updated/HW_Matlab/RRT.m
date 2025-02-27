%***************************************
%Author: Chaoqun Wang
%Date: 2019-10-15
%***************************************
% RRT算法
%% 流程初始化
clc
clear all; close all;
x_I=1; y_I=1;           % 设置初始点
x_G=799; y_G=799;       % 设置目标点（可尝试修改终点）
Thr=50;                 % 设置目标点阈值，用法：若当前节点和终点的欧式距离小于Thr，则跳出当前for循环
Delta= 30;              % 设置扩展步长  应该是stepsize
%% 建树初始化
T.v(1).x = x_I;         % T是我们要做的树，v是节点，这里先把起始点加入到T里面来
T.v(1).y = y_I; 
T.v(1).xPrev = x_I;     % 起始节点的父节点仍然是其本身
T.v(1).yPrev = y_I;
T.v(1).dist=0;          % 从父节点到该节点的距离，这里可取欧氏距离
T.v(1).indPrev = 0;     % 这个变量什么意思？根据下面代码来看，indPrev表示indexPrev，父节点的index
%% 开始构建树，作业部分
figure(1);
ImpRgb=imread('generate_RRT.png');
Imp=rgb2gray(ImpRgb);  %地图，255为白色，free部分
imshow(Imp)
xL=size(Imp,2);%地图x轴长度 列数
yL=size(Imp,1);%地图y轴长度 行数
hold on
plot(x_I, y_I, 'ro', 'MarkerSize',10, 'MarkerFaceColor','r');
plot(x_G, y_G, 'go', 'MarkerSize',10, 'MarkerFaceColor','g');% 绘制起点和目标点
count=1;%记录树T中节点的个数
bFind = false;

for iter = 1:3000
    x_rand=[];
    %Step 1: 在地图中随机采样一个点x_rand
    %提示：用（x_rand(1),x_rand(2)）表示环境中采样点的坐标
    x_rand(1) = rand * (xL-1) +1;%-1是为了保证随机生成的坐标不会超出地图的边界,+1是因为索引是从1开始的
    x_rand(2) = rand * (yL-1) +1;

    x_near=[];
    %Step 2: 遍历树，从树中找到最近邻近点x_near（计算每个节点到 x_rand 的距离，找出最近的一个节点作为 x_near。）
    %提示：x_near已经在树T里
    numNodes = length(T.v);
    nearest_dst = Inf;
    nearest_idx = 1;
    for node_idx = 1:numNodes
        tmp_dist = sqrt(sum(([T.v(node_idx).x T.v(node_idx).y]-[x_rand(1) x_rand(2)]).^2));%T中每个节点到x_rand的欧氏距离
        if tmp_dist < nearest_dst
            nearest_dst = tmp_dist;
            nearest_idx = node_idx;
        end
    end
    x_near(1) = T.v(nearest_idx).x;
    x_near(2) = T.v(nearest_idx).y;


    %Step 3: 扩展得到x_new节点
    %提示：注意使用扩展步长Delta
    dir=atan2(x_rand(1)-x_near(1),x_rand(2)-x_near(2));
    x_new = x_near + Delta.*[sin(dir) cos(dir)];

    
    %检查节点是否是collision-free（即是否feasiable），如果不collision-free，则继续下一次采样
    if ~collisionChecking(x_near,x_new,Imp) 
       continue;
    end
    count=count+1;
    
    %Step 4: 将x_new插入树T 
    %提示：新节点x_new的父节点是x_near
    T.v(count).x = x_new(1);
    T.v(count).y = x_new(2);
    T.v(count).xPrev = x_I;
    T.v(count).yPrev = y_I;
    T.v(count).dist = nearest_dst;
    T.v(count).indPrev = nearest_idx;

    
    %Step 5:检查是否到达目标点附近 
    %提示：注意使用目标点阈值Thr，若当前节点和终点的欧式距离小于Thr，则跳出当前for循环（退出前需要绘制出x_near和x_new之间的路径）
    check_dist = calDist(x_new, [x_G y_G]);
    if check_dist < Thr
    plot([x_near(1); x_new(1);], [x_near(2); x_new(2)], 'r', 'Linewidth', 3);
        hold on;
        bFind = true;
        break;
    end
    
    %Step 6:将x_near和x_new之间的路径画出来
    %提示 1：使用plot绘制，因为要多次在同一张图上绘制线段，所以每次使用plot后需要接上hold on命令
    %提示 2：在判断终点条件弹出for循环前，记得把x_near和x_new之间的路径画出来
    plot([x_near(1); x_new(1);], [x_near(2); x_new(2)], 'r', 'Linewidth', 3);

    pause(0.05); %暂停一会，使得RRT扩展过程容易观察
end

if T.v(count).x == T.v(end).x && T.v(count).y == T.v(end).y
    fprintf('T.v(count) == T.v(end), T.v(count): (%f, %f),  T.v(end): (%f, %f)\n', T.v(count).x, T.v(count).y,T.v(end).x, T.v(end).y);
else
    fprintf('T.v(count) != T.v(end)\n');
end

%% 路径已经找到，反向查询
if bFind
    path.pos(1).x = x_G; path.pos(1).y = y_G;
    path.pos(2).x = T.v(end).x; path.pos(2).y = T.v(end).y;%关键字end用于表示
    pathIndex = T.v(end).indPrev; % 终点加入路径
    j=0;
    while 1
        path.pos(j+3).x = T.v(pathIndex).x;
        path.pos(j+3).y = T.v(pathIndex).y;
        pathIndex = T.v(pathIndex).indPrev;
        if pathIndex == 1
            break
        end
        j=j+1;
    end  % 沿终点回溯到起点
    % 起点加入路径
    path.pos(end+1).x = x_I; %已经遍历完path中除了起点外的所有node，end+1表示新增一个元素，所以后面再调用end时就是访问添加后的最后一个元素了，没毛病
    path.pos(end).y = y_I;
    for j = 2:length(path.pos)
        plot([path.pos(j).x; path.pos(j-1).x;], [path.pos(j).y; path.pos(j-1).y], 'b', 'Linewidth', 3);
    end
else
    disp('Error, no path found!');
end





























