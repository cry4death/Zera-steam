import io,sys,re,os
B=chr(92)
s=io.open('PROMPTS.md',encoding='utf-8').read()
base=re.search(r"## ChatGPT \(Codex\).*?```\n(.*?)```",s,re.S).group(1)
tmp=os.path.normpath(sys.argv[1]+'/codex_tmp')
for id in ['G2','G3']:
    p=base.replace('Задача: G1','Задача: '+id)
    p=p.replace('скопируй zera во временную папку вне GameZ и zera','скопируй zera во временную папку '+tmp+B+id)
    p+="\nЭто повторный заход: GameZ"+B+"tasks"+B+"reviews"+B+id+".md с вердиктом ДОРАБОТКА — исправь ровно эти замечания. Работаешь без пользователя, вопросов не задавай.\n"
    io.open('runs/'+id+'_prompt.txt','w',encoding='utf-8').write(p)
