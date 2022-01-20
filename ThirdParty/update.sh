
# xcconfigs
sh repository.sh xcconfigs xcconfigs

# Starscream
sh repository.sh daltoniam Starscream
sh build.sh Starscream Starscream Starscream Starscream

# bonjour
sh repository.sh eugenebokhan bonjour
(cd repository/bonjour && swift package generate-xcodeproj)
sh build.sh bonjour Bonjour-Package Bonjour Bonjour

# ReactiveX
sh repository.sh ReactiveX RxSwift
sed -i '' "s/PRODUCT_NAME = RxSwift\;/PRODUCT_NAME = RxSwift\; SUPPORTS_MACCATALYST = YES\;/g" "repository/RxSwift/Rx.xcodeproj/project.pbxproj"
sed -i '' "s/PRODUCT_NAME = \"\$(TARGET_NAME)\"\;/PRODUCT_NAME = \"\$(TARGET_NAME)\"\; SUPPORTS_MACCATALYST = YES\;/g" "repository/RxSwift/Rx.xcodeproj/project.pbxproj"
sed -i '' "s/PRODUCT_NAME = RxCocoa\;/PRODUCT_NAME = RxCocoa\; SUPPORTS_MACCATALYST = YES\;/g" "repository/RxSwift/Rx.xcodeproj/project.pbxproj"
sh build.sh RxSwift RxSwift Rx RxSwift
sh build.sh RxSwift RxRelay Rx RxRelay
sh build.sh RxSwift RxCocoa Rx RxCocoa
