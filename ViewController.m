//
//  ViewController.m
//  GCD
//
//  Created by 曾宪杰 on 2018/1/14.
//  Copyright © 2018年 曾宪杰. All rights reserved.
//

#import "ViewController.h"
@interface ViewController ()
@property (assign)int seat;

@end

@implementation ViewController
{
    BOOL gcdFlag;
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self group];
//    doABC();
//    two();
//    syncConncurrent();
//    [self asyncMain];
//    [self syncMain];
//    [self targetQueue];
//    [self synchronizedWithReserveSeat];
    
  
    
    
}

#pragma mark - 线程锁
- (void)synchronizedWithReserveSeat {
    self.seat = 3;
    //    开启一个线程
    NSThread *thread1 = [[NSThread alloc]initWithTarget:self selector:@selector(ReserveSeat) object:nil];
    thread1.name = @"A";
    [thread1 start];
    //    开启一个线程
    NSThread *thread2 = [[NSThread alloc]initWithTarget:self selector:@selector(ReserveSeat) object:nil];
    thread2.name = @"B";
    [thread2 start];
}
-(void)ReserveSeat{
    //    我们必须座位预定完   也就是一直循环 直到seat属性没有值
    while (true) {
        // 注意，锁一定要是所有线程共享的对象
        // 如果代码中只有一个地方需要加锁，大多都使用 self
        @synchronized(self) {
            //            判断如果座位大于0  客户就可以预订
            if(self.seat > 0)
            {
                NSLog(@"预定%d号座位  ------%@",self.seat,[NSThread currentThread]);
                self.seat --;
            }else{
                NSLog(@"没有座位了 ------%@",[NSThread currentThread]);
                break;
            }
        }
    }
}


#pragma mark - 异步执行 + 并行队列
void doABC() {
      NSLog(@"---start---");
    //DISPATCH_QUEUE_CONCURRENT 并行，DISPATCH_QUEUE_SERIAL NULL一个一个执行
    dispatch_queue_t queue = dispatch_queue_create("lab", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        sleep(3);
         NSLog(@"异步执行 + 并行队列任务1---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        sleep(3);
        NSLog(@"异步执行 + 并行队列任务2---%@", [NSThread currentThread]);
    });
      NSLog(@"---end---");
}
#pragma mark - 主线程刷新
void two() {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"get_main_queue two");
    });
}
#pragma mark - 同步执行 + 并行队列
void syncConncurrent() {
    dispatch_queue_t que_t = dispatch_queue_create("b", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(que_t, ^{
         NSLog(@"同步执行 + 并行队列任务1---%@", [NSThread currentThread]);
    });
    dispatch_sync(que_t, ^{
        NSLog(@"同步执行 + 并行队列任务2---%@", [NSThread currentThread]);
    });
    dispatch_sync(que_t, ^{
        NSLog(@"同步执行 + 并行队列任务3---%@", [NSThread currentThread]);
    });
    
}
#pragma mark - 异步执行+主队列
- (void)asyncMain{
    //获取主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    NSLog(@"---start---");
    //使用异步函数封装三个任务
    dispatch_async(queue, ^{
        NSLog(@"任务1---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2---%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务3---%@", [NSThread currentThread]);
    });
}
#pragma mark - 同步 锁死
-(void)syncMain {
    dispatch_queue_t mainQu = dispatch_get_main_queue();
    NSLog(@"syncMain star");
//    这async后锁死
    dispatch_async(mainQu, ^{
         NSLog(@"任务1---%@", [NSThread currentThread]);
    });
     NSLog(@"end");

}

#pragma mark - 队列添加
- (void)targetQueue {
    dispatch_queue_t ququ = dispatch_queue_create("xj.ququ", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t globalQuqu =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_set_target_queue(ququ, globalQuqu);//往队列中添加一个队列，改变系统队列。
    dispatch_async(ququ, ^{
        NSLog(@"我优先级低，先让让");
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"我优先级高,我先block");
    });
}

#pragma mark - 异步执行 + 并行队列 + group
- (void)group {
    //doABC() 中的“主”队列
       dispatch_queue_t queue = dispatch_queue_create("lab", DISPATCH_QUEUE_CONCURRENT);
    //组队列
    dispatch_queue_t ququ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    //"主"队列放组
    dispatch_async(queue, ^{
        dispatch_group_async(group, ququ, ^{
            NSLog(@"group --- 1 %@\n",[NSThread currentThread]);
        });
        dispatch_group_async(group, ququ, ^{
            NSLog(@"group --- 2 %@\n",[NSThread currentThread]);
            sleep(3);
        });
        dispatch_group_async(group, ququ, ^{
            NSLog(@"group --- 3 %@\n",[NSThread currentThread]);
            
            dispatch_async(queue, ^{
                NSLog(@"group ------wait");
                sleep(3);
                dispatch_resume(ququ);
            });
        });
        //暂停
        dispatch_suspend(ququ);

    });
    
    dispatch_async(queue, ^{
       
        dispatch_wait(group, DISPATCH_TIME_FOREVER);
        
        NSLog(@"group ---end---wait");
        dispatch_group_t  group = dispatch_group_create();
        dispatch_group_async(group, ququ, ^{
            NSLog(@"group --- 4 %@\n",[NSThread currentThread]);
        });
        dispatch_group_async(group, ququ, ^{
            NSLog(@"group --- 5 %@\n",[NSThread currentThread]);
        });
        dispatch_group_notify(group, ququ, ^{
            NSLog(@"group ---finished");
        });
    });

}

#pragma mark - 信号
- (void)seamp {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);//为了让一次输出10个，初始信号量为10
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i <20; i++)
    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);//每进来1次，信号量-1;进来10次后就一直hold住，直到信号量大于0；
        dispatch_async(queue, ^{
            NSLog(@"%i, %@",i,[NSThread currentThread]);
            sleep(2);
            dispatch_semaphore_signal(semaphore);//由于这里只是log,所以处理速度非常快，我就模拟2秒后信号量+1;
        });
    }
}

- (IBAction)click:(UIButton *)sender {
    NSLog(@"btn click");
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
