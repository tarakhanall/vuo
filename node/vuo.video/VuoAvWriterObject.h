/**
 * @file
 * VuoAvWriter implementation.
 *
 * @copyright Copyright © 2012–2020 Kosada Incorporated.
 * This code may be modified and distributed under the terms of the MIT License.
 * For more information, see https://vuo.org/license.
 */

/// https://b33p.net/kosada/node/9140
#ifndef NS_RETURNS_INNER_POINTER
#define NS_RETURNS_INNER_POINTER
#endif
#import <Cocoa/Cocoa.h>
#undef NS_RETURNS_INNER_POINTER

#include "VuoMovieFormat.h"

/**
* Internal AVWriter implementation.  Use VuoAvWriter instead.
*/
@interface VuoAvWriterObject : NSObject

 ///< Is this object currently recording video?
- (BOOL) isRecording;

///< Setup a new AssetWriter and beging recording to it.
- (BOOL) setupAssetWriterWithUrl:(NSURL*) fileUrl imageWidth:(int)width imageHeight:(int)height channelCount:(int)channels movieFormat:(VuoMovieFormat)format;

/**
 * Add an image to the currently recording AVWriter.  setupAssetWriterUrl must have been called prior.
 * Use [VuoAvWriter appendImage].
 * @version200Changed{Added `blockIfNotReady` argument.}
 */
- (void) appendImage:(VuoImage)image presentationTime:(double)timestamp blockIfNotReady:(BOOL)blockIfNotReady;

/**
 * Adds a set of audio samples to this movie file.  setupAssetWriterWithUrl must have been called prior.
 * @version200Changed{Added `blockIfNotReady` argument.}
 */
- (void) appendAudio:(VuoList_VuoAudioSamples) samples presentationTime:(VuoReal)timestamp blockIfNotReady:(BOOL)blockIfNotReady;

/**
 * Finalize the currently recording video.
 */
- (void) finalizeRecording;

@end
