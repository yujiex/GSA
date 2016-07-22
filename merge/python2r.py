import os
import glob
import pandas as pd
import numpy as np
import get_building_set as gbs
import sqlite3
import util_io as uo
r_input = os.getcwd() + '/input_R/'

def write_robust_energy_set():
    s = gbs.get_energy_set('eui')
    conn = uo.connect('all')
    with conn:
        df = pd.read_sql('SELECT Building_Number, Cat FROM EUAS_category', conn)
    df['status'] = df['Building_Number'].map(lambda x: "Electric EUI >= 12 and Gas EUI >= 3for at least 6 years from FY2007 to FY2015" if x in s else 'Not robust energy')
    df.to_csv(r_input + 'robust_energy.csv', index=False)
    
def write_co_sets():
    (cap_only, op_only, cap_and_op, cap_or_op) = gbs.get_invest_set()
    no_invest = gbs.get_no_invest_set()
    df1 = pd.DataFrame({'Building_Number': list(cap_only)})
    df1['status'] = 'Capital Only'
    df2 = pd.DataFrame({'Building_Number': list(op_only)})
    df2['status'] = 'Operational Only'
    df3 = pd.DataFrame({'Building_Number': list(cap_and_op)})
    df3['status'] = 'Capital and Operational'
    df4 = pd.DataFrame({'Building_Number': list(no_invest)})
    df4['status'] = 'No Known Investment'
    df5 = pd.DataFrame({'Building_Number': list(cap_or_op)})
    df5['status'] = 'With Investment'
    df = pd.concat([df1, df2, df3, df4, df5], ignore_index=True)
    df.to_csv(r_input + 'cap_op_cnt.csv', index=False)
    print 'end'
    
def main():
    # write_robust_energy_set()
    write_co_sets()
    return
    
main()
