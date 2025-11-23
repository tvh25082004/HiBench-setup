#!/usr/bin/env python3
"""
HiBench Log Workflow Analyzer
Phân tích workflow từ benchmark logs và so sánh giữa các task khác nhau
"""

import re
import sys
import json
from pathlib import Path
from collections import defaultdict, OrderedDict
from datetime import datetime
from typing import Dict, List, Set, Optional


class LogWorkflowAnalyzer:
    """Phân tích workflow từ HiBench logs"""
    
    def __init__(self):
        self.workflow_patterns = {
            'prepare_phase': r'1️⃣\s+PREPARE PHASE|PREPARE PHASE|prepare phase',
            'run_phase': r'2️⃣\s+RUN PHASE|RUN PHASE|run phase',
            'report_phase': r'3️⃣\s+REPORT|REPORT',
            'spark_context_start': r'SparkContext.*Running Spark version',
            'spark_context_stop': r'SparkContext.*Successfully stopped',
            'job_start': r'Starting job|Job \d+ is finished',
            'job_finish': r'Job \d+ finished|Job.*completed',
            'stage_start': r'Submitting.*Stage|Stage \d+',
            'stage_finish': r'Stage \d+.*finished',
            'task_start': r'Starting task|Task \d+\.\d+',
            'task_finish': r'Finished task|Task \d+\.\d+.*finished',
            'dag_scheduler': r'DAGScheduler.*Submitting|DAGScheduler.*finished',
            'executor_added': r'Executor added|Granted executor',
            'shuffle': r'ShuffleMapStage|ResultStage',
            'hdfs_operations': r'hdfs.*-ls|hdfs.*-rm|hdfs.*-mkdir',
            'spark_submit': r'spark-submit|Submit Spark job',
            'hibench_report': r'HiBench Benchmark Report|hibench\.report'
        }
        
    def parse_log_file(self, log_path: Path) -> Dict:
        """Parse một log file và extract workflow"""
        if not log_path.exists():
            return None
            
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            lines = content.split('\n')
        
        workflow = {
            'file': str(log_path.name),
            'benchmark': self._extract_benchmark_name(log_path.name),
            'timestamp': self._extract_timestamp(log_path.name),
            'phases': {},
            'spark_events': [],
            'stages': [],
            'tasks': [],
            'durations': {},
            'errors': [],
            'workflow_steps': []
        }
        
        # Extract phases
        workflow['phases'] = self._extract_phases(content)
        
        # Extract Spark events
        workflow['spark_events'] = self._extract_spark_events(lines)
        
        # Extract stages
        workflow['stages'] = self._extract_stages(lines)
        
        # Extract tasks
        workflow['tasks'] = self._extract_tasks(lines)
        
        # Extract durations
        workflow['durations'] = self._extract_durations(content, lines)
        
        # Extract errors
        workflow['errors'] = self._extract_errors(lines)
        
        # Build workflow steps
        workflow['workflow_steps'] = self._build_workflow_steps(workflow)
        
        return workflow
    
    def _extract_benchmark_name(self, filename: str) -> str:
        """Extract benchmark name from filename"""
        match = re.search(r'benchmark-([^-]+)-([^-]+)-([^-]+)', filename)
        if match:
            return f"{match.group(1)}/{match.group(2)}"
        return "unknown"
    
    def _extract_timestamp(self, filename: str) -> Optional[str]:
        """Extract timestamp from filename"""
        match = re.search(r'(\d{8}_\d{6})', filename)
        return match.group(1) if match else None
    
    def _extract_phases(self, content: str) -> Dict:
        """Extract các phases từ log"""
        phases = {}
        
        # Prepare phase
        if re.search(self.workflow_patterns['prepare_phase'], content, re.IGNORECASE):
            phases['prepare'] = True
            prepare_match = re.search(r'Prepare phase completed', content, re.IGNORECASE)
            if prepare_match:
                phases['prepare_completed'] = True
        
        # Run phase
        if re.search(self.workflow_patterns['run_phase'], content, re.IGNORECASE):
            phases['run'] = True
        
        # Report phase
        if re.search(self.workflow_patterns['report_phase'], content, re.IGNORECASE):
            phases['report'] = True
        
        return phases
    
    def _extract_spark_events(self, lines: List[str]) -> List[Dict]:
        """Extract Spark events"""
        events = []
        
        for i, line in enumerate(lines):
            # Spark Context
            if re.search(self.workflow_patterns['spark_context_start'], line):
                events.append({'type': 'spark_context_start', 'line': i+1, 'content': line.strip()})
            if re.search(self.workflow_patterns['spark_context_stop'], line):
                events.append({'type': 'spark_context_stop', 'line': i+1, 'content': line.strip()})
            
            # Jobs
            if re.search(self.workflow_patterns['job_start'], line):
                events.append({'type': 'job_start', 'line': i+1, 'content': line.strip()})
            if re.search(self.workflow_patterns['job_finish'], line):
                events.append({'type': 'job_finish', 'line': i+1, 'content': line.strip()})
            
            # Executors
            if re.search(self.workflow_patterns['executor_added'], line):
                events.append({'type': 'executor_added', 'line': i+1, 'content': line.strip()})
        
        return events
    
    def _extract_stages(self, lines: List[str]) -> List[Dict]:
        """Extract Spark stages"""
        stages = []
        
        for i, line in enumerate(lines):
            # Stage submission
            stage_match = re.search(r'Submitting.*Stage (\d+)', line)
            if stage_match:
                stages.append({
                    'stage_id': stage_match.group(1),
                    'type': 'submitted',
                    'line': i+1
                })
            
            # Stage finish
            finish_match = re.search(r'Stage (\d+).*finished in ([\d.]+) s', line)
            if finish_match:
                stages.append({
                    'stage_id': finish_match.group(1),
                    'type': 'finished',
                    'duration': float(finish_match.group(2)),
                    'line': i+1
                })
        
        return stages
    
    def _extract_tasks(self, lines: List[str]) -> List[Dict]:
        """Extract Spark tasks"""
        tasks = []
        
        for i, line in enumerate(lines):
            # Task start
            task_start = re.search(r'Starting task (\d+\.\d+)', line)
            if task_start:
                tasks.append({
                    'task_id': task_start.group(1),
                    'type': 'start',
                    'line': i+1
                })
            
            # Task finish
            task_finish = re.search(r'Finished task (\d+\.\d+).*in ([\d]+) ms', line)
            if task_finish:
                tasks.append({
                    'task_id': task_finish.group(1),
                    'type': 'finish',
                    'duration': int(task_finish.group(2)),
                    'line': i+1
                })
        
        return tasks
    
    def _extract_durations(self, content: str, lines: List[str]) -> Dict:
        """Extract durations"""
        durations = {}
        
        # Total duration
        duration_match = re.search(r'Total Duration:\s*(\d+)s', content)
        if duration_match:
            durations['total'] = int(duration_match.group(1))
        
        # Job duration
        job_match = re.search(r'Job \d+ finished.*took ([\d.]+) s', content)
        if job_match:
            durations['job'] = float(job_match.group(1))
        
        return durations
    
    def _extract_errors(self, lines: List[str]) -> List[str]:
        """Extract errors và warnings"""
        errors = []
        
        for i, line in enumerate(lines):
            if re.search(r'ERROR|❌|Failed|Exception', line, re.IGNORECASE):
                errors.append(f"Line {i+1}: {line.strip()}")
        
        return errors
    
    def _build_workflow_steps(self, workflow: Dict) -> List[str]:
        """Build workflow steps sequence"""
        steps = []
        
        # Phase order
        if workflow['phases'].get('prepare'):
            steps.append('PREPARE')
        if workflow['phases'].get('run'):
            steps.append('RUN')
        if workflow['phases'].get('report'):
            steps.append('REPORT')
        
        # Spark workflow
        spark_events = [e['type'] for e in workflow['spark_events']]
        if 'spark_context_start' in spark_events:
            steps.append('SPARK_CONTEXT_START')
        if 'executor_added' in spark_events:
            steps.append('EXECUTOR_ADDED')
        if 'job_start' in spark_events:
            steps.append('JOB_START')
        if len(workflow['stages']) > 0:
            steps.append('STAGES_EXECUTION')
        if 'job_finish' in spark_events:
            steps.append('JOB_FINISH')
        if 'spark_context_stop' in spark_events:
            steps.append('SPARK_CONTEXT_STOP')
        
        return steps
    
    def compare_workflows(self, workflows: List[Dict]) -> Dict:
        """So sánh workflows giữa các benchmark"""
        comparison = {
            'common_steps': set(),
            'unique_steps': defaultdict(list),
            'step_frequency': defaultdict(int),
            'differences': []
        }
        
        if not workflows:
            return comparison
        
        # Collect all steps
        all_steps = []
        for wf in workflows:
            steps = tuple(wf['workflow_steps'])
            all_steps.append(steps)
            for step in wf['workflow_steps']:
                comparison['step_frequency'][step] += 1
        
        # Find common steps (steps that appear in all workflows)
        if all_steps:
            comparison['common_steps'] = set(all_steps[0])
            for steps in all_steps[1:]:
                comparison['common_steps'] &= set(steps)
        
        # Find unique steps
        for wf in workflows:
            benchmark = wf['benchmark']
            steps = set(wf['workflow_steps'])
            unique = steps - comparison['common_steps']
            if unique:
                comparison['unique_steps'][benchmark] = list(unique)
        
        # Find differences
        for i, wf1 in enumerate(workflows):
            for wf2 in workflows[i+1:]:
                steps1 = set(wf1['workflow_steps'])
                steps2 = set(wf2['workflow_steps'])
                diff = steps1.symmetric_difference(steps2)
                if diff:
                    comparison['differences'].append({
                        'benchmark1': wf1['benchmark'],
                        'benchmark2': wf2['benchmark'],
                        'differences': list(diff)
                    })
        
        return comparison
    
    def generate_report(self, workflows: List[Dict], comparison: Dict) -> str:
        """Generate báo cáo so sánh"""
        report = []
        report.append("=" * 80)
        report.append("HIBENCH WORKFLOW ANALYSIS REPORT")
        report.append("=" * 80)
        report.append("")
        
        # Individual workflows
        report.append("📊 INDIVIDUAL WORKFLOWS:")
        report.append("-" * 80)
        for wf in workflows:
            report.append(f"\n🔹 Benchmark: {wf['benchmark']}")
            report.append(f"   File: {wf['file']}")
            report.append(f"   Timestamp: {wf['timestamp']}")
            report.append(f"   Workflow Steps: {' → '.join(wf['workflow_steps'])}")
            report.append(f"   Phases: {', '.join(wf['phases'].keys())}")
            report.append(f"   Stages: {len(wf['stages'])}")
            report.append(f"   Tasks: {len(wf['tasks'])}")
            if wf['durations']:
                report.append(f"   Duration: {wf['durations']}")
            if wf['errors']:
                report.append(f"   ⚠️  Errors: {len(wf['errors'])}")
        
        # Comparison
        report.append("\n" + "=" * 80)
        report.append("🔍 WORKFLOW COMPARISON:")
        report.append("-" * 80)
        
        report.append(f"\n✅ Common Steps (appear in all workflows):")
        if comparison['common_steps']:
            report.append(f"   {', '.join(sorted(comparison['common_steps']))}")
        else:
            report.append("   (None)")
        
        report.append(f"\n🔸 Step Frequency:")
        for step, count in sorted(comparison['step_frequency'].items(), key=lambda x: -x[1]):
            report.append(f"   {step}: {count}/{len(workflows)} workflows")
        
        if comparison['unique_steps']:
            report.append(f"\n🔹 Unique Steps (per benchmark):")
            for benchmark, steps in comparison['unique_steps'].items():
                report.append(f"   {benchmark}: {', '.join(steps)}")
        
        if comparison['differences']:
            report.append(f"\n⚠️  Workflow Differences:")
            for diff in comparison['differences']:
                report.append(f"   {diff['benchmark1']} vs {diff['benchmark2']}:")
                report.append(f"      Differences: {', '.join(diff['differences'])}")
        
        report.append("\n" + "=" * 80)
        
        return "\n".join(report)


def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: analyze-log-workflow.py <log_file1> [log_file2] ...")
        print("   or: analyze-log-workflow.py --dir <logs_directory>")
        sys.exit(1)
    
    analyzer = LogWorkflowAnalyzer()
    workflows = []
    
    # Parse arguments
    if sys.argv[1] == '--dir':
        if len(sys.argv) < 3:
            print("Error: Please specify logs directory")
            sys.exit(1)
        logs_dir = Path(sys.argv[2])
        log_files = list(logs_dir.glob('*.log'))
        if not log_files:
            print(f"No log files found in {logs_dir}")
            sys.exit(1)
    else:
        log_files = [Path(f) for f in sys.argv[1:]]
    
    # Parse all log files
    print(f"📖 Analyzing {len(log_files)} log file(s)...\n")
    for log_file in log_files:
        print(f"   Parsing: {log_file.name}")
        workflow = analyzer.parse_log_file(log_file)
        if workflow:
            workflows.append(workflow)
    
    if not workflows:
        print("❌ No valid workflows found!")
        sys.exit(1)
    
    # Compare workflows
    comparison = analyzer.compare_workflows(workflows)
    
    # Generate report
    report = analyzer.generate_report(workflows, comparison)
    print("\n" + report)
    
    # Save report to file
    report_file = Path('logs/workflow-analysis-report.txt')
    report_file.parent.mkdir(exist_ok=True)
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)
    print(f"\n💾 Report saved to: {report_file}")


if __name__ == '__main__':
    main()

