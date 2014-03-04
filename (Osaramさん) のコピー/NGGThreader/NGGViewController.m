//
//  NGGViewController.m
//  NGGThreader
//
//  Created by Osamu Suzuki on 2014/02/28.
//  Copyright (c) 2014年 Plegineer, Inc. All rights reserved.
//

#import "NGGViewController.h"
//**マクロ値だからずっと変わらない数字
#define SCROLL_SPEED 5  //**スクロールの速さ
#define INTER_SPACE 100  //**障害物の間
#define TAG_BUILDING 10  //** ??
//osuzuki:Viewにtagというプロパティがあって、building(View)を分別するためにtagを設定してます！ 他のViewと区別するためです！デフォルトは0が入ってます。数字自体は0以外であればなんでもよかったです。
//updateViewの中のfor(UIView *scenary in self.sceneries)文内、if文で他のViewと区別してます
//osuzuki:注意!!!!!全角スペースにきをつけてください！エラーの原因となります。プログラマーが死にます。


typedef NS_ENUM(NSInteger, NGGViewStatus) { //**整数のステータスを返す
    NGGVIewStatusNone = 0,   //**0は0
    NGGVIewStatusStandby = 1, //**スタンバイステータスは１
    NGGVIewStatusAlive = 2,   //**活動中ステータスは２
    NGGVIewStatusGameOver = 3,　//**ゲームオーバーは3

};

@interface NGGViewController ()<UICollisionBehaviorDelegate> //**プロトコル宣言だから実装メソッドはなし？//osuzuki:プロトコルは、このメソッドを実装してますよーといった意思表示みたいなもので、これを宣言しといて、このメソッドを実装しないと警告がでます。ただし@optionalがつくと実装してなくてもok.
//**宣言プロパティで各種ラベル・ビューなど表示のみの設定？
@property (nonatomic, strong) UILabel *startLabel;
@property (nonatomic, strong) UILabel *gameOverLabel;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UIImageView *ballImageView;
@property (nonatomic, strong) UIImageView *groundImageView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UIPushBehavior *floatUpBehavior;
@property (nonatomic, strong) NSMutableArray *sceneries;
@property (nonatomic, assign) NGGViewStatus viewStatus;
@property (nonatomic, assign) NSInteger score;
@end

@implementation NGGViewController

//ViewControllerのViewが生成されたときに呼ばれる
//UIに関する部分はここでaddSubViewする
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //背景表示
    UIView *bgView = [[UIView alloc] initWithFrame:self.view.frame]; //**初期化
    bgView.backgroundColor = [UIColor colorWithRed:0 green:150.0f/255.0f blue:255.0f alpha:1.0f]; //**色決め
    [self.view addSubview:bgView];　//**実行//osuzuki:実行ではないですね。
    //osuzuki:まずselfは自分自身(NGGViewControllerオブジェクト)を指しています。
    //このViewController(self)には、独自のViewを持っていて、そのViewにbgViewを上からかぶせて、くっつけてるイメージです。
    //osuzuki:Viewをくっつけるメソッドは、addSubviewのほかにinsertSubviewとか色々あります。
    //osuzuki:subViewというのは、self.viewからbgViewをみたイメージです。bgViewからself.viewに対しては「parentView」といいます。
    //osuzuki:以下subview同様です。
    
    //ボール表示
    CGFloat ballWidth = 40;  //**大きさ（幅）
    CGFloat ballHeight = 40; //**大きさ（高さ）
    UIImageView *ballImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ball"]];　//**初期化+画像入れてる
    ballImageView.frame = CGRectMake(0, 0, ballWidth, ballHeight); //**表示位置??//osuzuki:そうです。
    ballImageView.center = CGPointMake([self displaySize].width/2, [self displaySize].height/2); //**??//osuzuki:位置をずらしてます。
    [self.view addSubview:ballImageView]; //**サブビューに表示実行??
    self.ballImageView = ballImageView;   //**メインビューに表示実行
    
    //地面表示
    UIImageView *groundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ground"]];  //**初期化+画像入れてる
    groundImageView.frame = CGRectMake(0, [self displaySize].height-40, 640, 40); //**表示位置??
    [self.view addSubview:groundImageView]; //**サブビューに表示実行??
    self.groundImageView = groundImageView;  //**メインビューに表示実行
    
    //スコアラベル表示
    UILabel *scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [self displaySize].width, 100)]; //**初期化+位置決めてる
    scoreLabel.backgroundColor = [UIColor clearColor]; //**背景色
    scoreLabel.textAlignment = NSTextAlignmentCenter;  //**直線で真ん中に表示する？
    scoreLabel.textColor = [UIColor whiteColor];  //**文字色
    scoreLabel.font = [UIFont boldSystemFontOfSize:32];　//**文字サイズ
    [self.view addSubview:scoreLabel]; //**サブビューに表示実行??
    self.scoreLabel = scoreLabel; //**メインビューへ表示実行？？//osuzuki:あとで使うので、viewcontrollerのプロパティとして保持してます
    [self updateScore];　　//**??//osuzuki:スコアを更新してます。下の方に書いてある、updateScoreメソッドを呼んでます。
    
    [self setStanbyLabel]; //**スタンバイラベルとは??//osuzuki:TAP TO START!って表示されるラベルです。
    _viewStatus = NGGVIewStatusStandby;  //**スタンバイラベルをステータスビューへ?
}

//メモリが切迫したときに呼ばれる
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//ステータスバー非表示
- (BOOL)prefersStatusBarHidden  //**ここでは作成したステータスバーを表示するかどうか決めてる？？
{
    return YES;
}

#pragma mark - Custom

//本来はUtililtyクラスつくってクラスメソッドとして呼びたい
//ディスプレイサイズ
- (CGSize)displaySize
{
    return [[UIScreen mainScreen] bounds].size; //**スクロール表示範囲をサイズ指定??//osuzuki:ここでは指定してないです。画面領域のサイズを取得しているだけです。
}

//重力とかビヘイビア（iOS7からの機能）を各オブジェクトに付与
- (void)setBehaviors
{     //**以下処理によってボールの重力を初期化して画像入れている
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    UIGravityBehavior *gravityBehvior = [[UIGravityBehavior alloc] initWithItems:@[self.ballImageView]];
    [animator addBehavior:gravityBehvior];
      //**以下処理でボールの衝突を初期化して・・・
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ballImageView]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES; //**境界線で跳ね返りOK
    collisionBehavior.collisionDelegate = self; //**デリゲート(別の処理場所?)衝突設定は自身に設定?//osuzuki:特に今回は使ってませんが、UICollisionBehaviorDelegateメソッド（例えば、衝突が起きたときに呼ばれるメソッドとか）を、self=自分自身で呼び出せるようにしてます。
    //それによって、衝突が起きた時に◯◯したいといった、処理がかけるようになります。このクラスの一番下に書いてます。特に処理は書いてませんが。
    [collisionBehavior addBoundaryWithIdentifier:@"ground" fromPoint:CGPointMake(0, self.groundImageView.frame.origin.y) toPoint:CGPointMake(self.groundImageView.frame.size.width, self.groundImageView.frame.origin.y)];　//**地面の設定なのは分かるのですが、どんな処理??
    //osuzuki:fromPointからtoPointまで、見えない線を設定し、その線にぶつかったらバウンドしますよ、という処理を書いてます。
    [animator addBehavior:collisionBehavior];
    
    UIPushBehavior *floatUpBeahavior = [[UIPushBehavior alloc] initWithItems:@[self.ballImageView] mode:UIPushBehaviorModeInstantaneous]; //**ボールをタップした瞬間の処理と初期化
    floatUpBeahavior.pushDirection = CGVectorMake(0, -0.5); //**ボールをタップしたときの動く方向??//osuzuki:そうです。
    floatUpBeahavior.active = NO; //**タップしたからといってその他のアクションはなし？//osuzuki:activeをYESに移動してしまいます
    [animator addBehavior:floatUpBeahavior];
    self.floatUpBehavior = floatUpBeahavior;
    
    
    //**ブロック文というのは分かるのですが、なぜブロック文を利用するのかがわかりませんので教えてくださーい??
    //物理アニメーションの設定ですかね？
    //osuzuki:actionというプロパティは、アニメーションが実行されている間呼ばれ続ける（何度も）処理を書く感じです。
    //「処理を書く」ので、オブジェクトを渡すのではないです。そういったときは、ブロック文を渡した方が都合がいいです。
    UIDynamicBehavior *scrollBehavior = [[UIDynamicBehavior alloc] init];
    scrollBehavior.action = ^ {
        [self updateViews];
    };
    [animator addBehavior:scrollBehavior];
    
    self.animator = animator;
    //osuzuki:UIDynamicAnimatorオブジェクトのanimatorがすべてのビヘイビアを管理します。
}

//ビューを更新
- (void)updateViews
{
    for(UIView *scenary in self.sceneries){ //**ビューの画面風景は自身?　背景は変わらないってこと?
         //osuzuki:sceneriesには、障害物のimageview（たくさん）と、地面画像のimageviewがはいってます
        scenary.center = CGPointMake(scenary.center.x-SCROLL_SPEED, scenary.center.y); //**ボールはセンター!!
        //**以下の処理は何をしてるのでしょうか？
        //osuzuki:障害物imageviewが、真ん中にきたときに、スコアをプラス1をして、スコア表示を更新してます
        if(scenary.tag == TAG_BUILDING
           && (int)(scenary.frame.origin.x+scenary.frame.size.width)==(int)([self displaySize].width/2)){
            self.score++;
            [self updateScore];
        }
    }
    //**
    //** <= - これってポイントを指しているんだと思うのですが、「始まりとビューは同じ画面になる?」ってことでしょうか?
    //osuzuki:ポインタじゃないんです（汗）　< と = があわさったもですよ。値の大小の比較です。
    if (self.groundImageView.frame.origin.x <= -[self displaySize].width) {
        self.groundImageView.center = CGPointMake([self displaySize].width, self.groundImageView.center.y);
        
        for(UIView *scenary in [self.sceneries reverseObjectEnumerator]){
            if(scenary.frame.origin.x+scenary.frame.size.width < 0){
                [scenary removeFromSuperview];
                [self.sceneries removeObject:scenary];
            }
        }
        
        [self setBuildingViews];
    }
    
    //衝突判定
    //**ぶつかったら、アニメーションを取り除く設定?や中央にラベルを表示する
    //osuzuki:そうです
    for (UIView *scenary  in self.sceneries) {
        if(CGRectIntersectsRect(self.ballImageView.frame, scenary.frame)){
            NSLog(@"Game Over!");
            [self setGameOverLabel];
            [self.animator removeAllBehaviors];
            _viewStatus = NGGVIewStatusGameOver;
            break;
        }
    }
}

//障害物表示
//**なんとなく分かります
- (void)setBuildingViews
{
    NSInteger offset = arc4random()%200-100;
    CGFloat downSideYPostion = [self displaySize].height/2 + offset;//[self displaySize].height/2 -+100
    
    UIImageView *upSideBuildingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"building"]];
    upSideBuildingImageView.frame = CGRectMake([self displaySize].width, downSideYPostion-400-INTER_SPACE, 60, 400);
    [self.view insertSubview:upSideBuildingImageView belowSubview:self.groundImageView];
    [self.sceneries addObject:upSideBuildingImageView];
    
    UIImageView *downSideBuildingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"building"]];
    downSideBuildingImageView.frame = CGRectMake([self displaySize].width, downSideYPostion, 60, 400);
    downSideBuildingImageView.tag = TAG_BUILDING;
    [self.view insertSubview:downSideBuildingImageView belowSubview:self.groundImageView];
    [self.sceneries addObject:downSideBuildingImageView];
}

//ゲームオーバー表示
//**ここもなんとか
- (void)setGameOverLabel
{
    UILabel *gameOverLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, [self displaySize].width, 200)];
    gameOverLabel.backgroundColor = [UIColor clearColor];
    gameOverLabel.textAlignment = NSTextAlignmentCenter;
    gameOverLabel.textColor = [UIColor whiteColor];
    gameOverLabel.text = @"GAME OVER";
    gameOverLabel.font = [UIFont boldSystemFontOfSize:32];
    [self.view addSubview:gameOverLabel];
    self.gameOverLabel = gameOverLabel;
}

//スタートラベル表示
//**ここもわかるような
- (void)setStanbyLabel
{
    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, [self displaySize].width, 200)];
    startLabel.backgroundColor = [UIColor clearColor];
    startLabel.textAlignment = NSTextAlignmentCenter;
    startLabel.textColor = [UIColor whiteColor];
    startLabel.text = @"TAP TO START!";
    startLabel.font = [UIFont boldSystemFontOfSize:32];
    [self.view addSubview:startLabel];
    self.startLabel = startLabel;
}

//リセット
//**ここも大丈夫です
- (void)resetViewsAndAnimator
{
    [self.startLabel removeFromSuperview];
    [self.gameOverLabel removeFromSuperview];
    [self.sceneries makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.sceneries = [NSMutableArray array];
    
    [self.animator removeAllBehaviors];
    
    self.ballImageView.center = CGPointMake([self displaySize].width/2, [self displaySize].height/2);
    self.groundImageView.frame = CGRectMake(0, [self displaySize].height-40, 640, 40);
    [self.view insertSubview:self.groundImageView belowSubview:self.ballImageView];
    [self.sceneries addObject:self.groundImageView];
    
    self.score = 0;
    [self updateScore];
}

//スコア更新
- (void)updateScore
{
    self.scoreLabel.text = [NSString stringWithFormat:@"%d",(int)self.score];
}

#pragma mark - Touch Event
//これはControl+6で各メソッドにジャンプするための目印みたいなもの

//タッチイベント UIResponderで実装
//タッチ開始時に呼ばれる

//**このイベントって宣言は必要ないやつですか?
//osuzuki:必要ないです。UIViewControllerはUIResponderを継承していて、UIResponder内で実装されているメソッドを呼んでいるので、宣言は必要ないです。
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@",NSStringFromSelector(_cmd)); //**タップしたらLogにだす
    if (_viewStatus == NGGVIewStatusAlive) { //**もし活動ステイタスがtureだと
        self.floatUpBehavior.active = YES;   //**
    }else if(_viewStatus == NGGVIewStatusGameOver){ //**ゲームオーバーステイタスがtureなら
        [self setStanbyLabel];  //**setStanbyLabel実行とアニメーションを削除する?
        [self.gameOverLabel removeFromSuperview];
        _viewStatus = NGGVIewStatusStandby;
    }else if (_viewStatus == NGGVIewStatusStandby){　　//**スタンダードステイタスがtureなら
        [self resetViewsAndAnimator];     //**あれっアニメーションとめる?
        [self setBehaviors];
        _viewStatus = NGGVIewStatusAlive;
    }
}

#pragma mark - UICollisionBehaviorDelegate

//衝突ビヘイビアのデリゲート
//**ここはどのような処理になるんでしょうか??
//osuzuki:衝突ビヘイビアを与えたアイテム（今回はボール）が、境界線と、衝突開始したときに呼ばれるメソッドです　- たぶん。
- (void)collisionBehavior:(UICollisionBehavior*)behavior beganContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier atPoint:(CGPoint)p
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

//osuzuki:衝突ビヘイビアを与えたアイテム（今回はボール）が、境界線と、衝突終了したときに呼ばれるメソッドです　- たぶん。
- (void)collisionBehavior:(UICollisionBehavior*)behavior endedContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
