/*****************************************************************
 *  copyright (c) 2010-2012, Michael D. Day
 *
 *  This work is licensed under the GNU GPL, version 2. See 
 *  http://www.gnu.org/licenses/gpl-2.0.txt
 *
 ****************************************************************/


#include <stdio.h>
#include <memory.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <getopt.h>
#include <errno.h>

/* 
   if no '<' or '>' AND (if '@ and '.') 
      just copy the buffer and return it, sans trailing garbage chars
   else
      if '<' AND '>' (AND < is lt >)
         copy < + 1 through > - 1

   strips the address string to only the actual address

    http://tools.ietf.org/html/rfc2822

   this isn't a proper RFC 2822 address parser, in fact it is
   embarrasingly crude. But it works ok for all the mbox files I have.
   It doesn't check for valid addresses. Presumably the address
   strings are all valid because they arrived in my mbox.

   The one problem I noticed is trailing non-printing chars at the 
   end of address strings, which is why the crude filtering out
   of trailing non-alphanumeric chars. Really ugly, and if I need
   to I will change to a proper email address parser.

*/

struct matched_addr 
{
	struct matched_addr *next;
	char *addr;
	char *line;
};

static struct matched_addr *matches =  NULL;


void add_matched_addr(const char *addr, const char *line)
{
	struct matched_addr *new_addr;

	if (!strlen(addr))
		return;
	
	new_addr = (struct matched_addr *)calloc(1, sizeof(struct matched_addr));
	if (!new_addr)
		return;
	new_addr->addr = strdup(addr);
	if (!new_addr->addr) {
		free(new_addr);
		return;
	}

	new_addr->line = strdup(line);
	if (!new_addr->line) {
		if (new_addr->addr)
			free(new_addr->addr);
		free(new_addr);
		return;
	}
	
	new_addr->next = matches;
	matches = new_addr;
}

int previously_matched(const char *addr, const char *line)
{
	struct matched_addr *a;
	const char *m;
	
	a = matches;
	
	if (addr == NULL || line == NULL)
		return 0;
	

	while (a != NULL && a->addr != NULL) {
		if (!strlen(a->addr))
			break;

 		m = strcasestr(addr, a->addr);
  		if (m != NULL)	{
			/* some lines are different but have the same address. */
			/* we want to match lines that are the same, and not */
			/* match lines that have the same address but are different. */
 			int no_match; 
			
 			no_match = strcasecmp(a->line, line);
 			if (no_match)
				return 1;
		}
		a = a->next;
	}
	return 0;
}

char *get_email_address(const char *addr_line)
{
	char *buf = NULL;

	
        /* see if we need to process the address */

	if (!strchr(addr_line, '<') && !strchr(addr_line, '>')) {
		const char *b = addr_line;
		char *e;
		
		/* strip trailing space and junk */
		buf = strdup(b);
		e = strchr(buf, '\0');
		while (e && *e < 33 || *e > 126) {
		        *e = '\0';
			e--;
		}
		
		if (strlen(buf) < 4)
			exit(0);
	}
	
	else {
		char *l_index, *r_index, *e;
		int len;
		e = strrchr(addr_line, '\0');
		l_index = strchr(addr_line, '<');
		r_index = strrchr(addr_line, '>');
		
		if (l_index && r_index && e && l_index < r_index && r_index < e) {
			len = r_index - l_index;
			buf = calloc(len + 1, sizeof(char));
			memcpy(buf, l_index + 1, len - 1);
			/* trim trailing white space */
			e = buf + len - 2;
			while (isspace(*e) || *e < 33 || *e > 126) {
				*e = '\0';
				e--;
			}
		}
	}
	return buf;
}



/* return the topmost <count> elements of the email domain */
/* if count == 0, return the entire domain string */

char *get_count_domain(int count, const char *addr)
{
	int domains = 0, skip = 0;
	char *p, *start, *domain = NULL, *buf = get_email_address(addr);

	if (!buf)
		return NULL;
	if (count < 0) 
		count = ~count + 1;
	
	start = strrchr(buf, '@');
	if (!start)
		goto out;
	start++;
		

	/* if count == 0 we are done */
	if (!count) {
		domain = strdup(start);
		goto out;
	}

	p = strrchr(buf, '\0');
	p--;
	
	while (p > start && count) {
		while(*p != '.' && p > start)
			p--;
		if (p == start)
			break;
		count--;
		if (count)
			p--;
	}
	
	if (*p == '.')
		p++;
	domain = strdup(p);

out:
	free(buf);
	return domain;
}



/*
  read each line in strings_to_search
  for each line, try to match search
  return number of matches
*/
int matches_in_file(FILE *search_file, const char *search)
{
	char buf[1024];
	char *line, *match;;
	int matches = 0;
	int haystack_len = 0;
	

	memset(buf, 0x00, 1024);
	fseek(search_file, 0, SEEK_SET);
	line = fgets(buf, 1023, search_file);
	do {
		if (line != NULL) {
			match = strcasestr(line, search);
			if (match != NULL) {
				match = NULL;
				matches++;
			}
		}
		memset(buf, 0x00, 1024);
		line = fgets(buf, 1023, search_file);
	} while (line != NULL);

	return matches;
}


int amat_usage(void)
{
	printf("amat [--needles <file>] --haystack <file> " \
	       "[--domain <count>] [--strip]\n");
	
	return 0;
	
}


int astrip_usage(void)
{
	printf("[astrip --needles <file>] [--domain <count>]\n");
	return -EINVAL;
}



static int domains, strip, csv, test;
static char *needles, *haystack;

static struct option long_options[] = {
	{"needles", required_argument, 0, 'n'},
	{"haystack", required_argument, 0, 'h'},
	{"domain", required_argument, 0, 'd'},
	{"strip", no_argument, 0, 1},
	{"csv", no_argument, 0, 'c'},
	{"test", no_argument, 0, 't'},
	{0,0,0,0}
};


void amat_check_options(FILE **n, FILE **h)
{
	if (haystack == NULL)
		*h = stdin;
	if (needles == NULL)
		*n = stdin;
	else
		*n = fopen(needles, "r");

	if (haystack)
		*h = fopen(haystack, "r");

	if (!*n || !*h)
		goto err_out;

	return;
	
err_out:
	if (needles && *n)
		fclose(*n);
	if (haystack && *h)
		fclose(*h);
	*n = *h = NULL;
	
	printf("Error opening needle or haystack file\n");
	exit (1);
}


void astrip_check_options(FILE **n)
{
	int err;
	
	if (needles == NULL)
		*n = stdin;
	else
		*n = fopen(needles, "r");
	
	if (!*n)
		exit (astrip_usage());
}

int amat_main(int argc, char **argv)
{
	int c, option_index = 0, matches = 0;
	FILE *needles_file = NULL, *haystack_file = NULL;
	char buf[1024], *line, *needle;
	
	if (argc < 1)
		exit (amat_usage());
	
	while (1) {


		c = getopt_long (argc, argv, "d:h:n:sc",
				 long_options, &option_index);
		
		/* Detect the end of the options. */
		if (c == -1)
			break;
		
		switch (c) {
		case 0:
			break;
		case 'n':
			needles = strdup(optarg);
			break;
		case 'h':
			haystack = strdup(optarg);
			break;

		case 'd':
			domains = strtol(optarg, NULL, 0);
			break;
			
		case 'c':
			csv = 1;
			break;
		case 't':
			test = 1;
			break;
		default:
			exit (amat_usage());
		}
	}

	amat_check_options(&needles_file, &haystack_file);

	do {
		memset(buf, 0x00, sizeof(buf));
		line = fgets(buf, 1023, needles_file);
		if (!line)
			break;
		if (strlen(line) < 4) {
			if (test)
				printf("tried to match a short line: %s\n", line);
			
			continue;
		}
		
		/* do we need to match the address or just the domain? */
		needle = get_email_address(line);

		if (previously_matched(needle, line)){
			if (test)
				printf("previously matched %s in %s", needle, line);
			
			free(needle);
			continue;
 		}
		if (needle) {
			matches = matches_in_file(haystack_file, needle);
			if (csv) {
 				char *nl = strrchr(line, '\n');
 				if (nl)
 					*nl = 0x00;
				if (!test)
					printf("\"%s\",\t%d\n", line, matches);
			} 
			else {
				if (!test)
					printf("%d\t%s", matches, line);
			}
			
			add_matched_addr(needle, line);
			free(needle);
		} else {
			if (test)
				printf("failed to extract address from: %s\n", line);
		}
		
	} while (line);
	
	if (needles && needles_file)
		fclose(needles_file);
	if (haystack_file)
		fclose(haystack_file);

	exit (0);
}

int astrip_main(int argc, char **argv)
{
	int c, option_index = 0;
	FILE *needles_file = NULL;
	char buf[1024], *line, *needle;

	while (1) {
		c = getopt_long(argc, argv, "d:n:", 
				long_options, &option_index);
		if (c == -1)
			break;
		
		switch(c) {
		case 'n':
			needles = strdup(optarg);
			break;
		case 'd':
			domains = strtol(optarg, NULL, 0);
			break;
		default:
			exit (astrip_usage());
			
		}
		
	}
	
	astrip_check_options(&needles_file);
	
	do {
		line = fgets(buf, 1023, needles_file);
		if (!line)
			break;

		/* do we strip to the bare address, or to only the domain component? */

		if (!domains)
			needle = get_email_address(line);
		else 
			needle = get_count_domain(domains, line);
		if (needle) {
			printf("%s\n", needle);
			free(needle);
		}
		
	} while (line);
		
	if (needles && needles_file)
		fclose(needles_file);
	exit (0);
}


struct git_matches {
	struct git_matches *next;
	char *domain;
	int commits;
	int added;
	int removed;
};

static struct git_matches *gmatches;

struct git_matches *new_match_node(const char *d, int c, int a, int r)
{
	if (d == NULL)
		return NULL;
	
	struct git_matches *newg = calloc(1, sizeof(struct git_matches));
	 if (! newg)
		 return NULL;

	 newg->domain = strdup(d);
	 if (! newg->domain) {
		 free(newg);
		 return NULL;
	 }
	 newg->commits = c;
	 newg->added = a;
	 newg->removed = r;

	 newg->next = gmatches;
	 gmatches = newg;

	 return newg;

 }

 struct git_matches *find_update_match_node(const char *d, int c, int a, int r)
 {
	 struct git_matches *searchg = gmatches;
	 char *sd, *search_domain = strdup(d);
	 if (!search_domain)
		 return NULL;
	 sd = search_domain;
	 
	 /* a little hack to collapse .com domains back to two levels */
	 char *com = strcasestr(sd, ".com");
	 if (com != NULL) {
		 /* is this a three-level .com domain? */
		 char *dot = strchr(sd, '.');
		 if (dot && dot != com) {
			 /* yes, a three-level domain */
			 sd = dot + 1;
		 }
	 }
	 
	 while (searchg != NULL) {
		 if (strcasestr(sd, searchg->domain) || 
		     strcasestr(searchg->domain, sd)) {
			 searchg->commits += c;
			 searchg->added += a;
			 searchg->removed += r;
			 free(search_domain);
			 return searchg;
		 }
		 searchg = searchg->next;
	 }
	 searchg = new_match_node(sd, c, a, r);
	 free(search_domain);
	 return searchg;
 }



struct git_matches *commits_in_file(const char *haystack, 
				    const char *needle,
				    int commits, int adds, int removes)
{
	struct git_matches *commit  = NULL;

	if (NULL != strcasestr(haystack, needle))
		commit = find_update_match_node(needle, 
						commits, 
						adds, 
						removes);
	return commit;
}


 int gitmatch_usage(void)
 {
	 printf("usage: gitmatch --haystack <haystack file> --needles <needles file> --csv\n");
	 return 1;
 }


 int gitmatch_main(int argc, char **argv)
 {
	 int c, option_index = 0, ccode_inner = 0, ccode_outer = 0;
	 int commits, adds, removes;
	 struct git_matches *commits_for_line = NULL; 
	 FILE *needles_file = NULL, *haystack_file = NULL;
	 char haystack_buf[1024], *line, needle[1024];


	 if (argc < 1)
		 exit(gitmatch_usage());
	 
	 while (1) {

		 c = getopt_long(argc, argv, "h:n:c", long_options, &option_index);

		 if (c == -1)
			 break;
		 switch(c) {
		 case 0:
			 break;
		 case 'n':
			 needles = strdup(optarg);
			 break;
		 case 'h':
			 haystack = strdup(optarg);
			 break;
		 case 'c':
			 csv = 1;
			 break;
		 default:
			 exit(gitmatch_usage());
		 }
	 }

	 amat_check_options(&needles_file, &haystack_file);

	 do {
		 memset(needle, 0x00, sizeof(needle));
		 ccode_outer  = fscanf(needles_file, "%1023s", needle);
		 if (ccode_outer == EOF)
			 break;
		 if (!ccode_outer)
			 continue;

		 do {
			 memset(haystack_buf, 0x00, sizeof(haystack_buf));
			 ccode_inner  = fscanf(haystack_file, "%1023s%d%d%d", 
			       haystack_buf, &commits, &adds, &removes);
			 if (ccode_inner == EOF)
				 break;
			 if (ccode_inner != 4)
				 continue;
			 commits_for_line = commits_in_file(haystack_buf, 
							    needle,
							    commits,
							    adds,
							    removes);
		 } while (ccode_inner != EOF);
		 /* seek to the beginning of the haystack file */
		 fseek(haystack_file, 0, SEEK_SET);
	 } while (ccode_outer  != EOF);
	 
	 /* now print the consolidated totals */
	 commits_for_line = gmatches;
	 

	 while (commits_for_line) {
		 if (csv)
			 printf("\"%s\", %d, %d, %d\n", 
				commits_for_line->domain, 
				commits_for_line->commits,
				commits_for_line->added,
				commits_for_line->removed);
		 else
			 printf("%s\t%d\t%d\t%d\n",
				commits_for_line->domain, 
				commits_for_line->commits,
				commits_for_line->added,
				commits_for_line->removed);
		 commits_for_line = commits_for_line->next;
	 } 
	 exit(0);
}

int main(int argc, char **argv)
{
	int err;

	if (strcasestr(argv[0], "gitmatch"))
		err = gitmatch_main(argc, argv);
	else if (strcasestr(argv[0], "astrip"))
		err = astrip_main(argc, argv);
	else
		err = amat_main(argc, argv);
	
        /* free needles, haystack */

	if (needles)
		free(needles);
	if (haystack)
		free(haystack);
	
	exit(err);
}
