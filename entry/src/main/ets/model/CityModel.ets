export class CityModel {
  id: number;
  name: string;
  dailyTemperatures: number[];
  continent: string;

  constructor(
    id: number = 0,
    name: string = '',
    dailyTemperatures: number[] = [],
    continent: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.dailyTemperatures = dailyTemperatures;
    this.continent = continent;
  }
}
