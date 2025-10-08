export class CityModel {
  id: number;
  name: string;
  dailyTemperatures: number[];

  constructor(
    id: number = 0,
    name: string = '',
    dailyTemperatures: number[] = []
  ) {
    this.id = id;
    this.name = name;
    this.dailyTemperatures = dailyTemperatures;
  }
}
