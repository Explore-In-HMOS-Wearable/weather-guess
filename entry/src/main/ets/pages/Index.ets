import { NavigationService } from '../services/NavigationService';
import { WeatherGuessGame } from './GameScreen';
import { HomeScreen } from './HomeScreen';

@Entry
@Component
struct Index {
  navigationService: NavigationService = NavigationService.getInstance();

  @Builder
  routeMap(name: string) {
    NavDestination() {
      if (name === 'Home') {
        HomeScreen()
      } else if (name === 'Game') {
        WeatherGuessGame()
      }
    }
    .onBackPressed(() => true)
    .hideTitleBar(true)
  }

  build() {
    Navigation(this.navigationService.pageInfos) {
      RelativeContainer() {
        HomeScreen()
      }
      .height('100%')
      .width('100%')
    }
    .mode(NavigationMode.Stack)
    .navDestination(this.routeMap)
    .ignoreLayoutSafeArea()
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
  }
}