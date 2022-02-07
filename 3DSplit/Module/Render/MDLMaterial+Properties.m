//
//  MDLMaterial+Properties.m
//  3DSplit
//
//  Created by kaoji on 2022/2/4.
//

#import "MDLMaterial+Properties.h"
#import <ModelIO/ModelIO.h>

@implementation MDLMaterial (Properties)

-(BOOL)setTexturePropertiesFromPath:(NSDictionary *)semantics{
    
    BOOL isSetProperty = NO;
    NSArray *allSemanticKeys = semantics.allKeys;
    for(NSString *key in allSemanticKeys){
        MDLMaterialSemantic semanticKey = key.intValue;
        NSString *path = semantics[key];
        NSURL * textureURL = [NSURL fileURLWithPath: path];
        MDLMaterialProperty *property = [[MDLMaterialProperty alloc] initWithName:path semantic:semanticKey URL:textureURL];
        [self setProperty: property];
        isSetProperty = YES;
    }
    return  isSetProperty;
}

@end
