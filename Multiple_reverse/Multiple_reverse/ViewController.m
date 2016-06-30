//
//  ViewController.m
//  Multiple_reverse
//
//  Created by Gopal Bharadia on 27/06/16.
//  Copyright © 2016 Gopal Bharadia. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    int number;
    int startRangeNumber;
    int endRangeNumber;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**Created by Gopal Krishan on 27/06/16 v1.0
 *
 * Function name: calculateAndPrintResult
 *
 * @description: IBAction for Print Result button
 * @parameter: sender.
 */
- (IBAction)calculateAndPrintResult:(id)sender {
    //validate all input numbers
    if ([self validateNumbers]) {
        number = [_txtNumberField.text intValue];
        startRangeNumber = [_txtStartRangeField.text intValue];
        endRangeNumber = [_txtEndRangeField.text intValue];
        //check start range with number.
        if (!(startRangeNumber % number == 0)) {
            startRangeNumber += number - (startRangeNumber % number);
        }
        
        //check end range with number.
        if (!(endRangeNumber % number == 0)) {
            endRangeNumber = endRangeNumber - (endRangeNumber % number);
        }
        //call recursive function
        NSLog(@"Multiple of %d is %d",number,[self printNumberRecursive:endRangeNumber]);
        
        // Initialize Alert Controller
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"See console log to see results" preferredStyle:UIAlertControllerStyleAlert];
        
        // Initialize Actions and add
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }]];
        
        // Present Alert Controller
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

/**Created by Gopal Krishan on 27/06/16 v1.0
 *
 * Function name: validateNumbers
 *
 * @description: function is used to validate the all input numbers like number, start range, end range.
 * @return: bool value.
 */
-(BOOL)validateNumbers{
    // Initialize bool with true
    BOOL isNumber = true;
    // Initialize errorMsg
    NSString *errorMsg = @"";
    
    //check for number
    if (!([_txtNumberField.text integerValue] >0)) {
        errorMsg = @"Please enter number greater than 0";
        isNumber = FALSE;
    }
    //check for start range
    else if (isNumber && !([_txtStartRangeField.text intValue] >0)){
        errorMsg = @"Please enter start range greater than 0";
        isNumber = FALSE;
    }
    //check for end range
    else if (isNumber && !([_txtEndRangeField.text intValue] >0)){
        errorMsg = @"Please enter end range greater than 0";
        isNumber = FALSE;
    }
    //check start range and end range (end range is grather than start range)
    else if (isNumber && ([_txtEndRangeField.text intValue] <= [_txtStartRangeField.text intValue])){
        errorMsg = @"Please enter end range greater than start range";
        isNumber = FALSE;
    }
    
    // check for bool value
    if (!isNumber) {
        
        // Initialize Alert Controller
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
        
        // Initialize Actions and add
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }]];
        
        // Present Alert Controller
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    return isNumber;
}

/**Created by Gopal Krishan on 27/06/16 v1.0
 *
 * Function name: printNumberRecursive
 *
 * @description: Recursive function is used to calculate the multiple of given number.
 * @return: bool value.
 */
-(int)printNumberRecursive:(int)operand{
    if (operand <= startRangeNumber) {
        return operand;
    }
    NSLog(@"Multiple of %d is %d",number,operand);
    return [self printNumberRecursive:operand - number];
}


@end
