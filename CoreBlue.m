//
//  CoreBlue.m
//  BLUE
//
//  Created by student on 16/9/14.
//  Copyright © 2016年 lyb. All rights reserved.
//

#import "CoreBlue.h"
#import <CoreBluetooth/CoreBluetooth.h>


@interface CoreBlue ()<CBCentralManagerDelegate,CBPeripheralDelegate>

/** 中心管理者 */
@property (nonatomic, strong)CBCentralManager *cMgr;

/** 连接到的外设 */
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, strong)NSMutableArray *muArray;

@end

@implementation CoreBlue

- (void)viewDidLoad{

    [super viewDidLoad];
    
    _muArray = @[].mutableCopy;
    
    self.title = @"中心设计模式";
    self.view.backgroundColor = [UIColor cyanColor];
    
    [self cMgr];
    
}

- (CBCentralManager *)cMgr{

    if (!_cMgr) {
        
        /*
         设置主设备的代理,CBCentralManagerDelegate
         必须实现的：
         - (void)centralManagerDidUpdateState:(CBCentralManager *)central;//主设备状态改变调用，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
         其他选择实现的代理中比较重要的：
         - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设
         - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功
         - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败
         - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设
         */

        _cMgr = [[CBCentralManager alloc]initWithDelegate:self
                                                    queue:dispatch_get_main_queue()
                                                  options:nil];
    }
    return _cMgr;
}

#pragma mark - CBCentralManagerDelegate
// 只要中心管理者初始化,就会触发此代理方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
        {
            NSLog(@"CBCentralManagerStatePoweredOn");
            // 在中心管理者成功开启后再进行一些操作
            // 搜索外设 CBCentralManagerOptionShowPowerAlertKey
            [self.cMgr scanForPeripheralsWithServices:nil // 通过某些服务筛选外设
                                              options:nil]; // dict,条件
            // 搜索成功之后,会调用我们找到外设的代理方法
            // - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设
            
        }
            break;
            
        default:
            break;
    }
}

// 发现外设后调用的方法
- (void)centralManager:(CBCentralManager *)central // 中心管理者
 didDiscoverPeripheral:(CBPeripheral *)peripheral // 外设
     advertisementData:(NSDictionary *)advertisementData // 外设携带的数据
                  RSSI:(NSNumber *)RSSI{ // 外设发出的蓝牙信号强度
    
   NSLog(@"%s, line = %d, cetral = %@,peripheral = %@, advertisementData = %@, RSSI = %@", __FUNCTION__, __LINE__, central, peripheral, advertisementData, RSSI);
    
    /*
     2016-09-14 15:34:25.966 BLUE[6937:4333830] -[CoreBlue centralManager:didDiscoverPeripheral:advertisementData:RSSI:], line = 127, cetral = <CBCentralManager: 0x14de96c50>,peripheral = <CBPeripheral: 0x14de33770, identifier = DECD4BAC-220B-0705-E993-E7E37A585757, name = FSRKB_BT_001, state = disconnected>, advertisementData = {
     kCBAdvDataIsConnectable = 1;
     kCBAdvDataLocalName = "FSRKB_BT-001";
     kCBAdvDataServiceUUIDs =     (
     FFF0
     );
     kCBAdvDataTxPowerLevel = 0;
     }, RSSI = -49
     */
    
    /*过滤条件
    1.设备名    FSRKB_BT-001
    2.信号强度  RSSI = -49
    3.
     */
    
    if ([peripheral.name hasPrefix:@"F"]&&(ABS(RSSI.integerValue) > 30)) {
        
        // 在此处对我们的 advertisementData(外设携带的广播数据) 进行一些处理
        // 通常通过过滤,我们会得到一些外设,然后将外设储存到我们的可变数组中,
        // 这里由于附近只有1个运动手环, 所以我们先按1个外设进行处理
        
        // 标记我们的外设,让他的生命周期 = vc
#warning 可能搜索到多个外设
        [_muArray addObject:peripheral];
        self.peripheral = peripheral;
        
        // 发现完之后就是进行连接
        [self.cMgr connectPeripheral:self.peripheral
                             options:nil];
        
        //NSLog(@"%s, line = %d ", __FUNCTION__, __LINE__);
    }
}

// 中心管理者连接外设成功
- (void)centralManager:(CBCentralManager *)central // 中心管理者
  didConnectPeripheral:(CBPeripheral *)peripheral{ // 外设

    NSLog(@"%s, line = %d, %@=连接成功", __FUNCTION__, __LINE__, peripheral.name);
    // 连接成功之后,可以进行服务和特征的发现
    // 4.1 获取外设的服务们
    // 4.1.1 设置外设的代理
    self.peripheral.delegate = self;
    
    [self.cMgr stopScan];//停止扫描
    
    // 4.1.2 外设发现服务,传nil代表不过滤
    // 这里会触发外设的代理方法 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
    [self.peripheral discoverServices:nil];
    
}

// 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
}

// 丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
}





#pragma mark - 外设代理
//搜索服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{

    //NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    // 判断没有失败
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
#warning 下面的方法中凡是有error的在实际开发中,都要进行判断
    }

    for (CBService *service in peripheral.services) {
        
        NSLog(@"%@",service.UUID);
        // 发现服务后,让设备再发现服务内部的特征 didDiscoverCharacteristicsForService
#warning 筛选服务 UUID   Device Information 设备信息
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FFF0"]]) {
            
            NSLog(@"－－－－－发现服务 %@－－－－",service.UUID);
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }

}

// 1 发现外设服务里的特征的时候调用的代理方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{

    if (error) {
        NSLog(@"搜索特征%@时发生错误:%@", service.UUID, [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *cha in service.characteristics) {
        NSLog(@"－－service:%@－－－发现特征 %@－－－－",service.UUID,cha.UUID);
#warning 设置监听特征
        NSLog(@"%s, line = %d, char = %@", __FUNCTION__, __LINE__, cha);
        // 获取特征对应的描述 didUpdateValueForDescriptor
        //[peripheral discoverDescriptorsForCharacteristic:cha];
        
#warning 晚上添加        
        //[peripheral setNotifyValue:YES forCharacteristic:cha];
        
        // 获取特征的值 didUpdateValueForCharacteristic
        //[peripheral readValueForCharacteristic:cha];
        
        if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF6"]]) {
            
            //读。重新获取characteristic的值
            /**
             -- 阅读文档查看需要对该特征的操作
             -- 读取成功回调didUpdateValueForCharacteristic
             */
            
            NSData *data = cha.value;
            Byte *bytes = (Byte *)[data bytes];
            for (int i=0; [data length]; i++) {
                
                NSLog(@"testByteFFF6[%d] = %d\n",i,bytes[i]);
            }
            
            //读取特征值  回调didUpdateValueForCharacteristic
            [peripheral readValueForCharacteristic:cha];
            //订阅通知值
            [peripheral setNotifyValue:YES forCharacteristic:cha];
        }
    }
    
    //for (CBCharacteristic *cha in service.characteristics) {
        
        //扫描描述  didDiscoverDescriptorsForCharacteristic
        //[peripheral discoverDescriptorsForCharacteristic:cha];
    //}
    
}

// 更新特征的描述的值的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    
    if (error) {
        NSLog(@"更新特征值  时发生错误:%@", [error localizedDescription]);
        return;
    }
    
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);

    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    // 这里当描述的值更新的时候,直接调用此方法即可
    //[peripheral readValueForDescriptor:descriptor];
    
    
}

//2 发现外设的特征的描述数组
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    //NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.descriptors);
    
    // 在此处读取描述即可
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        
        NSLog(@"Descriptor uuid:%@",descriptor.UUID);
        [peripheral readValueForDescriptor:descriptor];
    }
    
}

//3 更新特征的value的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    NSLog(@"%s, line = %d", __FUNCTION__, __LINE__);
    
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);
    
//    NSString *results = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    NSData *data = characteristic.value;
    Byte *results = (Byte *)[data bytes];
    NSInteger height = results[4];
    NSInteger low = results[5];
    NSInteger heart = results[6];
    
    NSLog(@"---%ld---",height);
    NSLog(@"---%ld---",low);
    NSLog(@"---%ld---",heart);
    
//    for (int i=0; i<data.length; i++) {
//        NSLog(@"---%hhu---",results[i]);
//    }
    
//    const char *hello = [data bytes];
//    int a;
//    memcpy(&a, hello, sizeof(int));
    
    
    
    //NSLog(@"－－－%ld－－－－",);//特征值
    
    
    
    //value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
//    for (CBDescriptor *descriptor in characteristic.descriptors) {
//        
//        // 这里当描述的值更新的时候,直接调用此方法即可
//        [peripheral readValueForDescriptor:descriptor];
//    }
}



#warning 晚上添加 订阅调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    if (error == nil ) {
        //调用下面的方法后 会调用到代理的-didUpdateValueForCharacteristic
        [peripheral readValueForCharacteristic:characteristic];
        NSLog(@"dsgfsdgsds");
    }
}



#pragma mark - 自定义方法
// 一般第三方框架or自定义的方法,可以加前缀与系统自带的方法加以区分.最好还设置一个宏来取消前缀

// 5.外设写数据到特征中

// 需要注意的是特征的属性是否支持写数据
- (void)yf_peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     
     打印出特征的权限(characteristic.properties),可以看到有很多种,这是一个NS_OPTIONS的枚举,可以是多个值
     常见的又read,write,noitfy,indicate.知道这几个基本够用了,前俩是读写权限,后俩都是通知,俩不同的通知方式
     */
    NSLog(@"%s, line = %d, char.pro = %lu", __FUNCTION__, __LINE__, (unsigned long)characteristic.properties);
    // 此时由于枚举属性是NS_OPTIONS,所以一个枚举可能对应多个类型,所以判断不能用 = ,而应该用包含&
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        // 核心代码在这里
        [peripheral writeValue:data // 写入的数据
             forCharacteristic:characteristic // 写给哪个特征
                          type:CBCharacteristicWriteWithResponse];// 通过此响应记录是否成功写入
    }
}

// 6.通知的订阅和取消订阅
// 实际核心代码是一个方法
// 一般这两个方法要根据产品需求来确定写在何处
- (void)yf_peripheral:(CBPeripheral *)peripheral regNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设为特征订阅通知 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
- (void)yf_peripheral:(CBPeripheral *)peripheral CancleRegNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设取消订阅通知 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

// 7.断开连接
- (void)yf_dismissConentedWithPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描
    [self.cMgr stopScan];
    // 断开连接
    [self.cMgr cancelPeripheralConnection:peripheral];
}


//-(void)writeCharacteristic:(CBPeripheral *)peripheral
//            characteristic:(CBCharacteristic *)characteristic
//                     value:(NSData *)value{
//    NSLog(@"%lu", (unsigned long)characteristic.properties);
//    
//    //只有 characteristic.properties 有write的权限才可以写
//    if(characteristic.properties & CBCharacteristicPropertyWrite){
//        /*
//         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
//         */
//        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//    }else{
//        
//        NSLog(@"该字段不可写！");
//    }
//    
//}
//
////设置通知
//-(void)notifyCharacteristic:(CBPeripheral *)peripheral
//             characteristic:(CBCharacteristic *)characteristic{
//    
//    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
//    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
//}
////取消通知
//-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
//                   characteristic:(CBCharacteristic *)characteristic{
//    
//    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
//}
//
////停止扫描并断开连接
//-(void)disconnectPeripheral:(CBCentralManager *)centralManager
//                 peripheral:(CBPeripheral *)peripheral{
//    //停止扫描
//    [self.cMgr stopScan];
//    //断开连接
//    [self.cMgr cancelPeripheralConnection:peripheral];
//}


@end
