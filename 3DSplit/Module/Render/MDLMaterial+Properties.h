//
//  MDLMaterial+Properties.h
//  3DSplit
//
//  Created by kaoji on 2022/2/4.
//

#import <ModelIO/ModelIO.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDLMaterial (Properties)

-(BOOL)setTexturePropertiesFromPath:(NSDictionary *)semantics;

@end

NS_ASSUME_NONNULL_END
