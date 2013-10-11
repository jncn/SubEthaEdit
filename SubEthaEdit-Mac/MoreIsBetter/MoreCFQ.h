/*	File:		MoreCFQ.h	Contains:	Core Foundation utility Routines.	Written by:	Quinn	Copyright:	Copyright (c) 2001 by Apple Computer, Inc., All Rights Reserved.	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.				("Apple") in consideration of your agreement to the following terms, and your				use, installation, modification or redistribution of this Apple software				constitutes acceptance of these terms.  If you do not agree with these terms,				please do not use, install, modify or redistribute this Apple software.				In consideration of your agreement to abide by the following terms, and subject				to these terms, Apple grants you a personal, non-exclusive license, under Apple�s				copyrights in this original Apple software (the "Apple Software"), to use,				reproduce, modify and redistribute the Apple Software, with or without				modifications, in source and/or binary forms; provided that if you redistribute				the Apple Software in its entirety and without modifications, you must retain				this notice and the following text and disclaimers in all such redistributions of				the Apple Software.  Neither the name, trademarks, service marks or logos of				Apple Computer, Inc. may be used to endorse or promote products derived from the				Apple Software without specific prior written permission from Apple.  Except as				expressly stated in this notice, no other rights or licenses, express or implied,				are granted by Apple herein, including but not limited to any patent rights that				may be infringed by your derivative works or by other works in which the Apple				Software may be incorporated.				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED				WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR				PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN				COMBINATION WITH YOUR PRODUCTS.				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR				CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE				GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)				ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION				OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT				(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN				ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.	Change History (most recent first):$Log: MoreCFQ.h,v $Revision 1.8  2003/04/04 15:01:49  eskimo1Added CFQCreateBundleFromFrameworkName.Revision 1.7  2003/02/26 20:49:25  eskimo1The GetValueAtPath APIs are "Get" and not "Copy" APIs, so they don't need *result == NULL as a precondition.Revision 1.6  2002/12/12 15:22:29  eskimo1Added CFQDictionaryMerge.Revision 1.5  2002/11/25 18:08:31  eskimo1Allow non-Carbon builds.Revision 1.4  2002/11/08 23:07:22  eskimo1When using framework includes, explicitly include the frameworks we need. Convert nil to NULL. Added CFQStringCopyCString.Revision 1.3  2002/10/24 11:46:27  eskimo1Added CFQError routines. Fixed non-framework includes build.Revision 1.2  2002/01/22 06:14:21  eskimo1Change CFQDictionaryAddNumber to CFQDictionarySetNumber.Revision 1.1  2002/01/16 22:51:32  eskimo1First checked in.*/#pragma once/////////////////////////////////////////////////////////////////// MoreIsBetter Setup#include "MoreSetup.h"// System Interfaces#if MORE_FRAMEWORK_INCLUDES	#include <CoreServices/CoreServices.h>#else	#include <CFBase.h>	#include <CFURL.h>	#include <CFPropertyList.h>	#include <CFBundle.h>	#include <Files.h>#endif/////////////////////////////////////////////////////////////////#ifdef __cplusplusextern "C" {#endif/////////////////////////////////////////////////////////////////#pragma mark ***** Trivial Utilitiesenum {	kCFQKeyNotFoundErr = 5400,	kCFQDataErr = 5401};extern pascal OSStatus CFQErrorBoolean(Boolean shouldBeTrue);extern pascal OSStatus CFQError(const void *shouldBeNotNULL);// Two wrappers around CFRelease/Retain that allow you to pass in NULL.extern pascal CFTypeRef CFQRetain(CFTypeRef cf);	// CFRetain if cf is not NULL.  Returns cf.	extern pascal void CFQRelease(CFTypeRef cf);	// CFRelease if cf is not NULL.extern pascal OSStatus CFQArrayCreateMutable(CFMutableArrayRef *result);	// Creates an empty CFMutableArray that holds other CFTypes.	//	// result must not be NULL.	// On input, *result must be NULL.	// On error, *result will be NULL.	// On success, *result will be an empty mutable array.extern pascal OSStatus CFQArrayCreateWithDictionaryKeys(CFDictionaryRef dict, CFArrayRef *result);extern pascal OSStatus CFQArrayCreateWithDictionaryValues(CFDictionaryRef dict, CFArrayRef *result);	// Creates an array that holds all of the keys (or values) of dict.	//	// dict must not be NULL.	// result must not be NULL.	// On input, *result must be NULL.	// On error, *result will be NULL.	// On success, *result will be an array.extern pascal OSStatus CFQDictionaryCreateMutable(CFMutableDictionaryRef *result);	// Creates an empty CFMutableDictionary that holds other CFTypes.	//	// result must not be NULL.	// On input, *result must be NULL.	// On error, *result will be NULL.	// On success, *result will be an empty mutable dictionary.extern pascal OSStatus CFQDictionaryCreateWithArrayOfKeysAndValues(CFArrayRef keys, 																   CFArrayRef values, 																   CFDictionaryRef *result);	// Creates a dictionary with the specified keys and values.	//	// keys must not be NULL.	// values must not be NULL.	// The length of keys and values must be the same.	// result must not be NULL.	// On input, *result must be NULL.	// On error, *result will be NULL.	// On success, *result will be an empty mutable dictionary.extern pascal OSStatus CFQDictionarySetNumber(CFMutableDictionaryRef dict, const void *key, long value);	// Set a CFNumber (created using kCFNumberLongType) in the 	// dictionary with the specified key.  If an error is returned 	// the dictionary will be unmodified.extern pascal OSStatus CFQStringCopyCString(CFStringRef str, CFStringEncoding encoding, char **cStrPtr);	// Extracts a C string from an arbitrary length CFString. 	// The caller must free the resulting string using "free".	// Returns kCFQDataErr if the CFString contains characters 	// that can't be encoded in encoding.	// 	// str must not be NULL	// On input,  cStrPtr must not be NULL	// On input, *cStrPtr must be NULL	// On error, *cStrPtr will be NULL	// On success, *cStrPtr will be a C string that you must free/////////////////////////////////////////////////////////////////#pragma mark ***** Dictionary Path Routinesextern pascal OSStatus CFQDictionaryGetValueAtPath(CFDictionaryRef dict, 												   const void *path[], CFIndex pathElementCount, 												   const void **result);	// Given a dictionary possibly containing nested dictionaries, 	// this routine returns the value specified by path.  path is 	// unbounded array of dictionary keys.  The first element of 	// path must be the key of a property in dict.  If path has 	// more than one element then the value of the property must 	// be a dictionary and the next element of path must be a 	// key in that dictionary.  And so on.  The routine returns 	// the value of the dictionary property found at the end 	// of the path.	//	// For example, if path is "A"/"B"/"C", then dict must contain 	// a property whose key is "A" and whose value is a dictionary. 	// That dictionary must contain a property whose key is "B" and 	// whose value is a dictionary.  That dictionary must contain 	// a property whose key is "C" and whose value this routine 	// returns.	//	// dict must not be NULL.	// path must not be NULL.	// pathElementCount must be greater than 0.	// result must not be NULL.	// On success, *result is the value from the dictionary.extern pascal OSStatus CFQDictionaryGetValueAtPathArray(CFDictionaryRef dict, 												   CFArrayRef path, 												   const void **result);	// This routine is identical to CFQDictionaryGetValueAtPath except 	// that you supply path as a CFArray instead of a C array.	//	// dict must not be NULL.	// path must not be NULL.	// path must have at least one element.	// result must not be NULL.	// On success, *result is the value from the dictionary.	extern pascal OSStatus CFQDictionarySetValueAtPath(CFMutableDictionaryRef dict, 												   const void *path[], CFIndex pathElementCount, 												   const void *value);	// This routines works much like CFQDictionaryGetValueAtPath 	// except that it sets the value at the end of the path 	// instead of returning it.  For the set to work, 	// dict must be mutable.  However, the dictionaries 	// nested inside dict may not be mutable.  To make this 	// work this routine makes a mutable copy of any nested 	// dictionaries it traverses and replaces the (possibly) 	// immutable nested dictionaries with these mutable versions. 	//	// The path need not necessarily denote an existing node 	// in the nested dictionary tree.  However, this routine 	// will only create a leaf node.  It won't create any 	// parent nodes required to holf that leaf.	//	// dict must not be NULL.	// path must not be NULL.	// pathElementCount must be greater than 0.extern pascal OSStatus CFQDictionarySetValueAtPathArray(CFMutableDictionaryRef dict, 												   CFArrayRef path, 												   const void *value);	// This routine is identical to CFQDictionarySetValueAtPath except 	// that you supply path as a CFArray instead of a C array.	// 	// dict must not be NULL.	// path must not be NULL.	// path must have at least one element.extern pascal OSStatus CFQDictionaryRemoveValueAtPath(CFMutableDictionaryRef dict, 												   const void *path[], CFIndex pathElementCount);	// This routines works much like CFQDictionarySetValueAtPath 	// except that it removes the value at the end of the path. 	//	// Unlike CFQDictionarySetValueAtPath, this routine requires 	// that path denote an existing node in the nested dictionary 	// tree.  Removing a non-existant node, even a leaf node, 	// results in an error.	// 	// dict must not be NULL.	// path must not be NULL.	// pathElementCount must be greater than 0.	extern pascal OSStatus CFQDictionaryRemoveValueAtPathArray(CFMutableDictionaryRef dict, 												   CFArrayRef path);	// This routine is identical to CFQDictionaryRemoveValueAtPathArray 	// except that you supply path as a CFArray instead of a C array.	// 	// dict must not be NULL.	// path must not be NULL.	// path must have at least one element.#ifdef __cplusplus}#endif