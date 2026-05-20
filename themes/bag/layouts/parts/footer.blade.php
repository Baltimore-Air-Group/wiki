{{--
    BAG theme override of resources/views/layouts/parts/footer.blade.php

    Adds a persistent BAG brand line. Unlike the upstream footer (which
    renders only when footer links are configured), this always shows the
    brand mark; the configured links remain optional.
--}}
<footer class="print-hidden bag-footer">
    <div class="bag-footer__inner">
        <span class="bag-footer__brand">Baltimore Air Group</span>
        @if(count(setting('app-footer-links', [])) > 0)
            <nav class="bag-footer__links">
                @foreach(setting('app-footer-links', []) as $link)
                    <a href="{{ $link['url'] }}" target="_blank" rel="noopener">{{ strpos($link['label'], 'trans::') === 0 ? trans(str_replace('trans::', '', $link['label'])) : $link['label'] }}</a>
                @endforeach
            </nav>
        @endif
    </div>
</footer>
