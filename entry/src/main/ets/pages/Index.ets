import { HomeScreen } from './HomeScreen';

@Entry
@Component
struct Index {

	build() {
		RelativeContainer() {
			HomeScreen()
		}
		.height('100%')
		.width('100%')
	}
}