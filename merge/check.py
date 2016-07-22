import sqlite3
import pandas as pd
import numpy as np
import os
import glob
import util_io as uo
import seaborn as sns
import pylab as P
import matplotlib.pyplot as plt
from datetime import datetime

import util_io as uo
import get_building_set as gbs
homedir = os.getcwd() + '/csv_FY/'
inputdir = os.getcwd() + '/input/FY/interval/0624/'
weatherdir = os.getcwd() + '/csv_FY/weather/'
my_dpi = 70

def compare_interval_db(b):
    conn = uo.connect('ION data.db')
    with conn:
        df = read_sql('SELECT * FROM ION_electricity WHERE Building_Number = \'{0}\''.format(b))
    df.info()

def check_covered_component():
    ids = gbs.get_covered_set()
    f_ids = [x for x in ids if '0000' in x]
    b_ids = [x for x in ids if not '0000' in x]
    euas = gbs.get_all_building_set()
    print len(euas)
    print 'total {0}, facility {1}, building {2}'.format(len(ids), len(f_ids), len(b_ids))
    for f in f_ids:
        dfs = []
        df = uo.view_building(f, 'Electric_(kBtu)')
        bs = [x for x in euas if '{0}0000{1}'.format(x[:2], x[-2:]) == f and not '0000' in x]
        if len(bs) == 0:
            print 'no building under {0}'.format(f)
            continue
        dfs.append(df)
        for b in bs:
            df = uo.view_building(b, 'Electric_(kBtu)')
            dfs.append(df)
        df_all = pd.concat(dfs, ignore_index=True)
        df_all.sort(['year', 'month', 'Building_Number'], inplace=True)
        print 'write to {0}.csv'.format(f)
        df_all.to_csv(homedir + 'question/facility_building/{0}.csv'.format(f), index=False)

def facility_vs_building_set(s):
    print s
    conn = uo.connect('all')
    if s == 'AI':
        ids = gbs.get_cat_set(['A', 'I'], conn)
    elif s == 'covered':
        ids = gbs.get_covered_set()
        df_f = pd.read_csv(os.getcwd() + '/input/FY/covered/Covered_Facilities_All Energy mmBTUs_FY14_EISA07Sec432_input.csv')
        facility_eisa = set(df_f['Facility_Number'].tolist())
        facility_eisa = [x[:8] for x in facility_eisa if type(x) != float]
    f_ids = [x for x in ids if '0000' in x]
    # for x in sorted(f_ids):
    #     print x
    b_ids = [x for x in ids if not '0000' in x]
    print 'total {0}, facility {1}, building {2}'.format(len(ids), len(f_ids), len(b_ids))
    bf_ids = ['{0}0000{1}'.format(x[:2], x[-2:]) for x in b_ids]
    print len(common)
    common = (set(bf_ids).intersection(f_ids))
    for y in common:
        print y
        print [x for x in b_ids if '{0}0000{1}'.format(x[:2], x[-2:]) == y]
    if s == 'covered':
        print 'eisa facility', len(facility_eisa)
        print 'common ids from eisa', len(set(f_ids).intersection(facility_eisa))
        print 'different ids from eisa', (set(f_ids).difference(facility_eisa))
        common = (set(f_ids).difference(facility_eisa))
        for y in common:
            print y
            print [x for x in b_ids if '{0}0000{1}'.format(x[:2], x[-2:]) == y]

def eisa_building_in_euas():
    df = pd.read_csv(os.getcwd() + '/input/FY/covered/Covered_Facilities_All Energy mmBTUs_FY14_EISA07Sec432_input.csv')
    buildings = df['Building_Number'].unique()
    facility = df['Facility_Number'].unique()
    print 'total building {0}, total facility {1}'.format(len(buildings), len(facility))
    euas = gbs.get_all_building_set()
    print len(euas.intersection(buildings)), len(euas.intersection(facility))
    print euas.intersection(buildings)

def facility_vs_building():
    # facility_vs_building_set('AI')
    facility_vs_building_set('covered')
    return

def check_interval(filename):
    df = pd.read_csv(inputdir + filename)
    df.rename(columns=lambda x: x[:8] if x != 'Timestamp' else x,
              inplace=True)
    df.dropna(axis=1, how='all', inplace=True)
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    df.set_index(pd.DatetimeIndex(df['Timestamp']), inplace=True)
    # df.info()
    df_re = df.resample('M', how='sum')
    cols = list(df_re)
    df_re.reset_index(inplace=True)
    df_long = pd.melt(df_re, id_vars='index', value_vars=cols)
    # print
    # print df_long.head()
    df_long.rename(columns={'index':'Timestamp', 'variable': 'Building_Number', 'value': 'Electricity_(KWH)'}, inplace=True)
    df_long['month'] = df_long['Timestamp'].map(lambda x: x.month)
    df_long['year'] = df_long['Timestamp'].map(lambda x: x.year)
    col_str = ','.join(['\'{0}\''.format(x) for x in cols])
    conn = uo.connect('all')
    with conn:
        df = pd.read_sql('SELECT Building_Number, year, month, [Electricity_(KWH)] FROM EUAS_monthly WHERE Building_Number IN ({0}) AND year = \'2015\''.format(col_str), conn)
    # print df.head()
    df_long.drop('Timestamp', axis=1, inplace=True)
    df_all = pd.merge(df, df_long, how='left', on=['Building_Number', 'year', 'month'], suffixes=['_EUAS', '_ION'])
    df_all['ratio'] = df_all['Electricity_(KWH)_ION']/df_all['Electricity_(KWH)_EUAS'].map(lambda x: round(x, 3))
    df_all['percent_diff'] = df_all['ratio'].map(lambda x: abs(1 - x) * 100.0)
    # print df_all.head()
    return df_all
    # print df_all[['percent_diff']].describe()
    
def plot_diff():
    df = pd.read_csv(inputdir + 'cmp/summary.csv')
    gr = df.groupby('Building_Number')
    sns.set_style("whitegrid")
    sns.set_context("talk", font_scale=1.0)
    sns.set_palette(sns.color_palette('Set2'))
    for name, group in list(gr):
        line1, = plt.plot(group['month'], group['Electricity_(KWH)_EUAS'], '-o')
        line2, = plt.plot(group['month'], group['Electricity_(KWH)_ION'], '-o')
        total_ion = group['Electricity_(KWH)_ION'].sum(axis=1)
        total_euas = group['Electricity_(KWH)_EUAS'].sum(axis=1)
        # if total_euas != 0:
        #     percent_diff = 1 - (total_ion/total_euas)
        # else:
        #     percent_diff = None
        ratio = total_ion / total_euas
        plt.title('Building {0} Total ION/Total EUAS {1}'.format(name, ratio))
        plt.legend([line1, line2], 
            ['EUAS monthly', 'ION monthly aggregated'], loc = 2, 
            bbox_to_anchor=(1, 1))
        plt.gca().set_ylim(bottom=0)
        P.savefig(inputdir + 'cmp/plot/{0}'.format(name), dpi = my_dpi, figsize = (2000/my_dpi, 500/my_dpi), bbox_inches='tight')
        plt.close()
    # plt.show()

def output_diff():
    df1 = check_interval('BKS_AA_CMU_MA.csv')
    df2 = check_interval('BKS_AA_CMU_region_1_exceptMA.csv')
    df = pd.concat([df1, df2], ignore_index=True)
    df.to_csv(inputdir + 'cmp/summary.csv', index=False)
    print df[['percent_diff']].describe()
    return
    
def check_hourly(b, measure_type):
    conn = uo.connect('interval_ion')
    euas_dict = {'electric': 'Electricity_(KWH)', 'gas': 'Gas_(Cubic_Ft)'}
    ion_dict = {'electric': 'Electric_(KWH)', 'gas':'Gas_(CubicFeet)'}
    with conn:
        df1 = pd.read_sql('SELECT * FROM {1} WHERE Building_Number = \'{0}\''.format(b, measure_type), conn)
    conn.close()
    df1['Date'] = pd.DatetimeIndex(pd.to_datetime(df1['Timestamp']))
    df1.set_index(df1['Date'], inplace=True)
    df1_re = df1.resample('M', 'sum')
    df1_re['month'] = df1_re.index.month
    df1_re['year'] = df1_re.index.year
    df1_re.reset_index(inplace=True)
    conn = uo.connect('all')
    with conn:
        df2 = pd.read_sql('SELECT Building_Number, year, month, [{1}] FROM EUAS_monthly WHERE Building_Number = \'{0}\''.format(b, euas_dict[measure_type]), conn)
    if len(df1) == 0 or len(df2) == 0:
        return
    df_all = pd.merge(df1_re, df2, on=['year', 'month'], how='left')
    df_all.set_index(pd.DatetimeIndex(pd.to_datetime(df_all['Date'])), inplace=True)
    df_all.drop('Date', axis=1, inplace=True)
    df_all.rename(columns={ion_dict[measure_type]: 'ION', euas_dict[measure_type]: 'EUAS'}, inplace=True)

    df_inn = pd.merge(df1_re, df2, on=['year', 'month'], how='inner')
    df_inn.set_index(pd.DatetimeIndex(pd.to_datetime(df_inn['Date'])), inplace=True)
    df_inn.drop('Date', axis=1, inplace=True)
    df_inn.rename(columns={ion_dict[measure_type]: 'ION', euas_dict[measure_type]: 'EUAS'}, inplace=True)
    df_inn[b] = df_inn['ION']/df_inn['EUAS']
    # df_inn.to_csv(homedir + 'temp/{0}_{1}_ion_euas.csv'.format(b, measure_type)) # temp check the data
    dsc = df_inn[[b]].describe().transpose()
    dsc['overall'] = df_inn['ION'].sum()/df_inn['EUAS'].sum()
    sns.set_context("talk", font_scale=1.0)
    sns.set_palette(sns.color_palette('Set2'))
    line1, = plt.plot(df_all.index, df_all['ION'], '-o')
    line2, = plt.plot(df_all.index, df_all['EUAS'], '-o')
    plt.legend([line1, line2], ['ION', 'EUAS'], loc='center left', bbox_to_anchor=(1, 0.5))
    plt.title('{0} {1} ION vs EUAS monthly'.format(b, measure_type), fontsize=30)
    if measure_type == 'electric':
        plt.ylabel('KWH')
    else:
        plt.ylabel('Cubic Feet')
    # plt.show()
    path = os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/{0}_{1}.png'.format(b, measure_type)
    P.savefig(path, dpi = my_dpi, figsize = (2000/my_dpi, 500/my_dpi), bbox_inches='tight')
    plt.close()
    return dsc

def check_match(conn, measure_type):
    with conn:
        df = pd.read_sql('SELECT * FROM {0}_id'.format(measure_type),
                         conn)
    ids = df['id']
    dfs = []
    for b in ids:
        print b
        dsc = check_hourly(b, measure_type)
        dfs.append(dsc)
    df_all = pd.concat(dfs)
    df_all.sort('75%', inplace=True)
    path = os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/{0}_ratio.csv'.format(measure_type)
    df_all.to_csv(path)
    return

def check_0711():
    # conn = uo.connect('interval_ion')
    # check_match(conn, 'electric')
    # check_match(conn, 'gas')
    # conn.close()
    keys = ['mean', 'std', 'min', '25%', '50%', '75%', 'max', 'overall']
    format_dict = {k: lambda x: '{0:.2f}'.format(x) for k in keys}
    uo.csv2html(os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/electric_ratio.csv', {'Unnamed: 0': 'Building_Number'}, format_dict)
    uo.csv2html(os.getcwd() + '/input/FY/interval/ion_0627/cmp_euas/gas_ratio.csv', {'Unnamed: 0': 'Building_Number'}, format_dict)
    return

# demonstrate the '0000' rule to identify facility number does not apply
def show_covered_exception(b, **kwargs):
    euas = gbs.get_all_building_set()
    print b in euas
    bs = [x for x in euas if '{0}0000{1}'.format(x[:2], x[-2:]) == b]
    if 'bs' in kwargs:
        bs = kwargs['bs']
    dfs = []
    df = uo.view_building(b, 'Electric_(kBtu)')
    dfs.append(df)
    if 'year' in kwargs:
        year = kwargs['year']
        df = df[(df['year'] == year) & (df['month'].isin([1, 2, 3]))]
        print b
        print df[['Region_No.', 'month', 'Electric_(kBtu)']]
    for x in bs[:3]:
        print x
        df = uo.view_building(x, 'Electric_(kBtu)')
        if 'year' in kwargs:
            year = kwargs['year']
            df = df[(df['year'] == year) & (df['month'].isin([1, 2, 3]))]
        dfs.append(df)
        if 'year' in kwargs:
            print
            print df[['Region_No.', 'month', 'Electric_(kBtu)']]
    df_all = pd.concat(dfs, ignore_index=True)
    df_all.drop(['year', 'month'], axis=1, inplace=True)
    df_all.sort(['Fiscal_Year', 'Fiscal_Month', 'Building_Number'],
                inplace=True)
    print 'write to {0}.csv'.format(b)
    df_all.to_csv(homedir + 'question/facility_building/{0}.csv'.format(b), index=False)
    return

def change_area():
    conn = uo.connect('all')
    with conn:
        df = pd.read_sql('SELECT Building_Number, [Gross_Sq.Ft] FROM EUAS_area', conn)
    df_max = df.groupby('Building_Number').max()
    df_min = df.groupby('Building_Number').min()
    df_all = pd.merge(df_max, df_min, how='inner', left_index=True, right_index=True, suffixes=['_max', '_min'])
    df_all['diff'] = df_all['Gross_Sq.Ft_max'] - \
                     df_all['Gross_Sq.Ft_min']
    df_all['percent_diff'] = df_all.apply(lambda r: np.nan if r['Gross_Sq.Ft_max'] == 0 else (1 - r['Gross_Sq.Ft_min']/r['Gross_Sq.Ft_max']) * 100, axis=1)
    df_large = df_all[df_all['percent_diff'] > 10]
    print len(df_large)
    df_large.drop('diff', axis=1, inplace=True)
    print df_large.head()
    df_large.to_csv(homedir + 'question/change_area.csv', index=True)
    return
    
def ecm_program_no_date():
    conn = uo.connect('all')
    with conn:
        df = pd.read_sql('SELECT * FROM EUAS_ecm_program', conn)
    df = df[df['ECM_program'].notnull()]
    df.drop_duplicates(cols=['Building_Number', 'ECM_program'], inplace=True)
    df.rename(columns={'ECM_program': 'energy_program'}, inplace=True)
    df.to_csv(homedir + 'question/program_date.csv', index=False)
    return

def euas_covered():
    covered = gbs.get_covered_set()
    euas = gbs.get_all_building_set()
    good_elec = gbs.get_energy_set('eui_elec')
    good_gas = gbs.get_energy_set('eui_gas')
    print len(covered.intersection(euas))
    print len(covered.intersection(good_elec))
    print len(covered.intersection(good_gas))

def check_0706():
    # euas_covered()
    ion_gsalink_time()
    return

def ion_gsalink_time():
    df = pd.read_csv(os.getcwd() + \
                     '/input/FY/interval/ion_0627/summary_long/summary_electric.csv')
    df = df[['Building_Number', 'min_time']]
    conn = uo.connect('other_input')
    with conn:
        df_gsalink = pd.read_sql('SELECT Building_ID as Building_Number, Rollout_Date as GSALink_start_time FROM  GSAlink_Buildings_First_55_Opiton_26_Start_Stop_Dates', conn)
    df_all = pd.merge(df, df_gsalink, on='Building_Number', how='left')
    df_all.rename(columns={'min_time': 'ION_start_time'}, inplace=True)
    df_all['GSALink_start_time'] = df_all['GSALink_start_time'].map(lambda x: np.nan if type(x) == float else datetime.strptime(x, '%Y/%m/%d').strftime('%Y-%m-%d'))
    df_all['ION_start_time'] = df_all['ION_start_time'].map(lambda x: np.nan if type(x) == float else datetime.strptime(x, '%Y-%m-%d %H:%M:%S').strftime('%Y-%m-%d'))
    df_all['days_diff'] = (pd.to_datetime(df_all['GSALink_start_time']) - pd.to_datetime(df_all['ION_start_time']))/np.timedelta64(1, 'D')
    df_all.to_csv(os.getcwd() + '/input/FY/interval/ion_0627/ion_gsalink_start.csv')
    print len(df_all[df_all['days_diff'] > 100])
    return
    
def missing_area():
    conn = uo.connect('interval_ion')
    with conn:
        df_area = pd.read_sql('SELECT * FROM area', conn)
        id_elec = pd.read_sql('SELECT id FROM electric_id', conn)
        id_gas = pd.read_sql('SELECT id FROM gas_id', conn)
    ids = np.union1d(id_elec['id'], id_gas['id'])
    missing = np.setdiff1d(ids, df_area['Building_Number'])
    print
    for x in missing:
        print x

def main():
    # missing_area()
    # check_0711()
    # check_0706()
    # b = 'FL0067ZZ'
    # compare_interval_db(b)
    # ecm_program_no_date()
    # change_area()
    # plot_diff()
    # facility_vs_building()
    # eisa_building_in_euas()
    # show_covered_exception('MD0000WO', 2015)
    # show_covered_exception('MD0000AG', 2015)
    # show_covered_exception('PA0000ER', bs=['PA0064ZZ', 'PA0644ZZ', 'PA0600ZZ'])
    # show_covered_exception('MD0000AG', bs=['MD0778AG', 'MD0767AG'])
    # set(['MD0778AG', 'MD0767AG', 'PA0064ZZ', 'PA0644ZZ', 'PA0600ZZ'])
    # check_covered_component()
    return
    
main()
