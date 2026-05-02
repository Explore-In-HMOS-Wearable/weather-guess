import { NavigationService } from '../services/NavigationService';
import { WeatherGuessGame } from './GameScreen';
import { HomeScreen } from './HomeScreen';
import { StatsScreen } from './StatsScreen';

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
      } else if (name === 'Stats') {
        StatsScreen()
      }
    }
    .onBackPressed(() => false)
    .hideTitleBar(true)
    .backgroundColor(Color.White)
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