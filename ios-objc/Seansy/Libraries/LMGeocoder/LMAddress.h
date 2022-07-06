//
//  Copyright (c) Năm 2014 LMinh.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LMAddress : NSObject <NSCopying, NSCoding>

/*!
*  The location coordinate
*/
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/*!
 *  The precise street address
 */
@property (copy, nonatomic) NSString *streetNumber;

/*!
 *  The named route
 */
@property (copy, nonatomic) NSString *route;

/*!
 *  The incorporated city or town political entity
 */
@property (copy, nonatomic) NSString *locality;

/*!
 *  The first-order civil entity below a localit
 */
@property (copy, nonatomic) NSString *subLocality;

/*!
 *  The civil entity below the country level
 */
@property (copy, nonatomic) NSString *administrativeArea;

/*!
 *  The Postal/Zip code
 */
@property (copy, nonatomic) NSString *postalCode;

/*!
 *  The country name
 */
@property (copy, nonatomic) NSString *country;

/*!
 *  The ISO country code (e.g. AU)
 */
@property (copy, nonatomic) NSString *countryCode;

/*!
 *  The formatted address
 */
@property (copy, nonatomic) NSString *formattedAddress;

/*!
 *  Response from server is usable
 */
@property (nonatomic, assign) BOOL isValid;

/*!
 *  Initialize with response from server
 *
 *  @param locationData response object recieved from server
 *  @param serviceType  pass here kLMGeocoderGoogleService or kLMGeocoderAppleService
 *
 *  @return object with all data set for use
 */
- (id)initWithLocationData:(id)locationData forServiceType:(int)serviceType;

@end
