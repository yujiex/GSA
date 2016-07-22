import sqlite3
import pandas as pd
import os
import glob
import shutil

homedir = os.getcwd() + '/csv_FY/'

def connect(db):
    conn = sqlite3.connect('{0}/db/{1}.db'.format(homedir, db))
    return conn

# print dictionary d with 'limit' number of records
def print_dict(d, limit):
    count = 0
    iterator = iter(d)
    while count < limit:
        key = next(iterator)
        print '{0} -> {1}'.format(key, d[key])
        count += 1

def view_building(b, col):
    conn = connect('all')
    df = pd.read_sql('SELECT DISTINCT Building_Number, Fiscal_Year, Fiscal_Month, year, month, [Gross_Sq.Ft], [Region_No.], Cat, [{1}] FROM EUAS_monthly WHERE Building_Number = \'{0}\''.format(b, col), conn)
    return df

def dir2html_wtemplate(dirname, suffix, title, outfile):
    files = glob.glob(dirname + suffix)
    print len(files)
    lines = []
    lines.append('<!DOCTYPE html>')
    lines.append('<html>')
    lines.append('<head>')
    lines.append('<title>{0}</title>'.format(title))
    lines.append('<h1>{0}</h1>'.format(title))
    if '.png' in suffix:
        template = '<h2>name</h2>\n<img src="file" alt="No Data" style="width:700px;height:auto;">'
    for f in files:
        relative = f[- len(f) + len(dirname):]
        filename = f[f.rfind('/') + 1: f.find(suffix[1:])]
        line = template.replace('file', relative)
        line = line.replace('name', filename)
        lines.append(line)
    lines.append('</body>')
    lines.append('</html>')
    with open(dirname + outfile, 'w+') as wt:
        wt.write('\n'.join(lines))
    print 'end'
    return

def dir2html(dirname, suffix, title, outfile):
    files = glob.glob(dirname + suffix)
    print len(files)
    lines = []
    lines.append('<!DOCTYPE html>')
    lines.append('<html>')
    lines.append('<head>')
    lines.append('<title>{0}</title>'.format(title))
    lines.append('<h1>{0}</h1>'.format(title))
    if '.png' in suffix:
        template = '<h2>name</h2>\n<img src="file" alt="No Data" style="width:700px;height:auto;">'
    for f in files:
        relative = f[- len(f) + len(dirname):]
        filename = f[f.rfind('/') + 1: f.find(suffix[1:])]
        line = template.replace('file', relative)
        line = line.replace('name', filename)
        lines.append(line)
    lines.append('</body>')
    lines.append('</html>')
    with open(dirname + outfile, 'w+') as wt:
        wt.write('\n'.join(lines))
    print 'end'
    return

# dir2html(os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/', '*_gas.png', 'gas ION vs EUAS', 'gas_cmp.html')
# dir2html(os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/', '*_electric.png', 'electric ION vs EUAS', 'electric_cmp.html')
# files = glob.glob(os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/*')
# for f in files:
#     shutil.copyfile(f, f.replace('/input/FY/interval/ion_0627/', '/plot_FY_weather/html/single_building/interval/'))
