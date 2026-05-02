import { hilog } from '@kit.PerformanceAnalysisKit';

class Logger {
  private domain: number;
  private prefix: string;

  constructor(prefix: string) {
    this.prefix = prefix;
    this.domain = 0xFF00;
  }

  debug(...args: string[]): void {
    hilog.debug(this.domain, this.prefix, '%{public}s', args.join(', '));
  }

  info(...args: string[]): void {
    hilog.info(this.domain, this.prefix, '%{public}s', args.join(', '));
  }

  warn(...args: string[]): void {
    hilog.warn(this.domain, this.prefix, '%{public}s', args.join(', '));
  }

  error(...args: string[]): void {
    hilog.error(this.domain, this.prefix, '%{public}s', args.join(', '));
  }
}

export default new Logger('[Sample_Graphics3d]');